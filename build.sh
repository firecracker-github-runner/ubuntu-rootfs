#!/bin/bash

# fail if we encounter an error, uninitialized variable or a pipe breaks
set -eu -o pipefail
set -x
PS4='+\t '

cd $(dirname $0)
ROOT_DIR=$PWD
OUTPUT_DIR=${ROOT_DIR}/dist

# Make sure we have all the needed tools
function install_dependencies {
    sudo apt update
    sudo apt install -y squashfs-tools tree mmdebstrap
}

function get_variant_path {
    local variant=$1
    local variant_path="${ROOT_DIR}/variants/${variant}"
    echo $variant_path
}

function get_variant_packages {
    local variant=$1
    local variant_path=$(get_variant_path $variant)
    local variant_packages=$(cat ${variant_path}/packages.txt | tr '\n' ',' | sed 's/,$//')
    echo $variant_packages
}

function apply_variant_chroot {
    local variant=$1
    local rootfs=$2
    local variant_path=$(get_variant_path $variant)
    local variant_chroot="${variant_path}/chroot.sh"
    sudo cp $variant_chroot $rootfs/
    sudo chroot $rootfs /bin/bash -c "./chroot.sh"
    sudo rm $rootfs/chroot.sh
}

# Build a rootfs
function build_rootfs {
    local ROOTFS_NAME=ubuntu-22.04
    local rootfs="tmp_rootfs"
    mkdir -pv "$rootfs" "$OUTPUT_DIR"

    local base_path=$(get_variant_path base)
    local base_packages=$(get_variant_packages base)

    # use SOURCE_DATE_EPOCH for reproducible builds
    export SOURCE_DATE_EPOCH=$(cat ${ROOT_DIR}/SOURCE_DATE_EPOCH)

    sudo mmdebstrap \
        --verbose \
        --arch=amd64 \
        --variant=minbase \
        --include="${base_packages}" \
        --dpkgopt='path-exclude=/usr/share/man/*' \
        --dpkgopt='path-exclude=/usr/share/locale/*' \
        --dpkgopt='path-include=/usr/share/locale/locale.alias' \
        --dpkgopt='path-exclude=/usr/share/doc/*' \
        --dpkgopt='path-include=/usr/share/doc/*/copyright' \
        --dpkgopt='path-exclude=/usr/share/{doc,info,man,omf,help,gnome/help}/*' \
        --format=dir \
        jammy \
        $rootfs < $base_path/overlay/etc/apt/sources.list

    sudo mkdir -p "${rootfs}/overlay"
    sudo mkdir -p "${rootfs}/working"
    sudo mkdir -p "${rootfs}/rom"
    sudo rm -f "${rootfs}/etc/resolv.conf" # rm symlink
    sudo cp -rvf $base_path/overlay/* $rootfs/

    # Runs a script inside the chroot
    apply_variant_chroot base $rootfs

    # Go for some last space saving
    sudo rm -rf "${rootfs}/var/log" \
                "${rootfs}/var/cache" \
                "${rootfs}/var/lib/apt/lists" \
                "${rootfs}/usr/share/bash-completion" \
                "${rootfs}/tmp/*" \

    local rootfs_img="$OUTPUT_DIR/$ROOTFS_NAME.squashfs"
    sudo mksquashfs $rootfs $rootfs_img -all-root -noappend -mkfs-time 0 -all-time 0 -no-progress -comp xz -Xbcj x86 -no-xattrs
    sudo chown -Rc $USER. $OUTPUT_DIR
}

#### main ####

sudo rm -r ${ROOT_DIR}/working || true
sudo rm -r ${OUTPUT_DIR} || true

mkdir -p ${ROOT_DIR}/working
pushd ${ROOT_DIR}/working > /dev/null

install_dependencies
build_rootfs

tree -h $OUTPUT_DIR

mkdir hashes
pushd hashes > /dev/null
find "$OUTPUT_DIR" -type f -exec sh -c 'sha256sum "{}" | tee "$(basename "{}").sha256.txt"' \;
mv *.sha256.txt $OUTPUT_DIR/
popd > /dev/null

popd > /dev/null
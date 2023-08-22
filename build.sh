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

# Build a rootfs
function build_rootfs {
    local ROOTFS_NAME=ubuntu-22.04
    local rootfs="tmp_rootfs"
    mkdir -pv "$rootfs" "$OUTPUT_DIR"

    sudo mmdebstrap \
        --arch=amd64 \
        --include='bash,apt,sudo,dbus,locales,udev,systemd,systemd-sysv,procps,libseccomp2,curl,iproute2' \
        --variant=minbase \
        --format=dir \
        --dpkgopt='path-exclude=/usr/share/man/*' \
        --dpkgopt='path-exclude=/usr/share/locale/*' \
        --dpkgopt='path-include=/usr/share/locale/locale.alias' \
        --dpkgopt='path-exclude=/usr/share/doc/*' \
        --dpkgopt='path-include=/usr/share/doc/*/copyright' \
        --dpkgopt='path-exclude=/usr/share/{doc,info,man,omf,help,gnome/help}/*' \
        jammy \
        $rootfs < $ROOT_DIR/overlay/etc/apt/sources.list

    sudo mkdir -p "${rootfs}/overlay"
    sudo mkdir -p "${rootfs}/working"
    sudo mkdir -p "${rootfs}/rom"
    sudo cp -rvf $ROOT_DIR/overlay/* $rootfs/

    # Runs a script inside the chroot
    sudo cp $ROOT_DIR/chroot.sh $rootfs/
    sudo chroot $rootfs /bin/bash -c "./chroot.sh"
    sudo rm $rootfs/chroot.sh

    # Go for some last space saving
    sudo rm -rf "${rootfs}/var/log" \
                "${rootfs}/var/cache" \
                "${rootfs}/var/lib/apt/lists" \
                "${rootfs}/usr/share/bash-completion" \
                "${rootfs}/tmp/*" \

    local rootfs_img="$OUTPUT_DIR/$ROOTFS_NAME.squashfs"
    sudo mksquashfs $rootfs $rootfs_img -all-root -noappend
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
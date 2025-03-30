#!/bin/bash

# fail if we encounter an error, uninitialized variable or a pipe breaks
set -eux -o pipefail

cd $(dirname $0)
ROOT_DIR=$PWD
OUTPUT_DIR=${ROOT_DIR}/dist

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
    cp $variant_chroot $rootfs/
    chroot $rootfs /bin/bash -c "./chroot.sh"
    rm $rootfs/chroot.sh
}

# Build a rootfs
function build_rootfs {
    local variant=$1

    echo "Building rootfs for variant: $variant"

    local rootfs="tmp_rootfs-${variant}"
    mkdir -pv "$rootfs"

    local base_path=$(get_variant_path base)
    local base_packages=$(get_variant_packages base)
    local variant_path=$(get_variant_path $variant)
    local variant_packages=$(get_variant_packages $variant)
    local sources_list=$(cat ${base_path}/overlay/etc/apt/sources.list)

    mmdebstrap \
        --verbose \
        --arch=amd64 \
        --variant=minbase \
        --include="${base_packages},${variant_packages}" \
        --dpkgopt='path-exclude=/usr/share/man/*' \
        --dpkgopt='path-exclude=/usr/share/locale/*' \
        --dpkgopt='path-include=/usr/share/locale/locale.alias' \
        --dpkgopt='path-exclude=/usr/share/doc/*' \
        --dpkgopt='path-include=/usr/share/doc/*/copyright' \
        --dpkgopt='path-exclude=/usr/share/{doc,info,man,omf,help,gnome/help}/*' \
        --format=directory \
        noble \
        "$rootfs" \
        "$sources_list"

    mkdir -p "${rootfs}/overlay"
    mkdir -p "${rootfs}/rom"
    rm -f "${rootfs}/etc/resolv.conf" # rm symlink

    cp -v $ROOT_DIR/COMMIT_HASH $ROOT_DIR/SOURCE_DATE_EPOCH $rootfs/root/

    cp -rvf $base_path/overlay/* $rootfs/
    apply_variant_chroot base $rootfs

    mv -v $rootfs/root/manifest $OUTPUT_DIR/ubuntu-${variant}-22.04.manifest.txt

    cp -rvf $variant_path/overlay/* $rootfs/
    apply_variant_chroot $variant $rootfs

    # Go for some last space saving
    rm -rf "${rootfs}/var/log/*" \
        "${rootfs}/var/cache/*" \
        "${rootfs}/var/lib/apt/lists" \
        "${rootfs}/usr/share/bash-completion" \
        "${rootfs}/tmp/*"

    # It's not supposed to, but APT seems to need this
    mkdir -p /var/cache/apt/archives/partial

    local rootfs_img="$OUTPUT_DIR/ubuntu-${variant}-22.04.squashfs"
    mksquashfs $rootfs $rootfs_img -all-root -noappend -no-progress -no-xattrs -comp zstd -Xcompression-level 19 -no-recovery -b 1M
}

function generate_img_hashes {
    local files=$(ls $OUTPUT_DIR/*.squashfs)
    for file in $files; do
        sha256sum "$file" | tee "$file.sha256.txt"
    done
}

function main {
    rm -r ${ROOT_DIR}/working || true
    rm -r ${OUTPUT_DIR} || true
    mkdir -p ${OUTPUT_DIR}

    mkdir -p ${ROOT_DIR}/working
    pushd ${ROOT_DIR}/working >/dev/null

    # use SOURCE_DATE_EPOCH for reproducible builds
    export SOURCE_DATE_EPOCH=$(cat ${ROOT_DIR}/SOURCE_DATE_EPOCH)

    # write COMMIT_HASH, so we can include it in the image
    echo "${COMMIT_HASH}" >${ROOT_DIR}/COMMIT_HASH

    echo "COMMIT_HASH: $(cat ${ROOT_DIR}/COMMIT_HASH)"
    echo "SOURCE_DATE_EPOCH: $(cat ${ROOT_DIR}/SOURCE_DATE_EPOCH)"

    build_rootfs minimal
    build_rootfs debug
    build_rootfs runner
    chown -Rc $UID $OUTPUT_DIR

    generate_img_hashes

    tree -h $OUTPUT_DIR

    popd >/dev/null
}

main "$@"

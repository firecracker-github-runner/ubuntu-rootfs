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
    sudo apt install -y unzip squashfs-tools tree debootstrap sudo
}

# Build a rootfs
function build_rootfs {
    local ROOTFS_NAME=ubuntu-22.04
    local rootfs="tmp_rootfs"
    mkdir -pv "$rootfs" "$OUTPUT_DIR"

    sudo debootstrap --arch=amd64 --variant=minbase --no-merged-usr --include=udev,systemd,systemd-sysv,procps,libseccomp2,sudo,bash jammy $rootfs http://archive.ubuntu.com/ubuntu/
    sudo rm -rf "${rootfs}/var/cache/apt/archives" \
                "${rootfs}/usr/share/{doc,man,info,locale}" \
                "${rootfs}/var/lib/apt/lists" \
                "${rootfs}/sbin"
    sudo cp -rf "${rootfs}/usr/sbin" "${rootfs}/sbin"
    sudo mkdir -p "${rootfs}/overlay"
    sudo mkdir -p "${rootfs}/working"
    sudo mkdir -p "${rootfs}/mnt/rom"
    sudo cp -rvf $ROOT_DIR/overlay/* $rootfs/
    local rootfs_img="$OUTPUT_DIR/$ROOTFS_NAME.squashfs"
    sudo mksquashfs $rootfs $rootfs_img -all-root -noappend
    sudo chown -Rc $USER. $OUTPUT_DIR
}

#### main ####

rm -r ${ROOT_DIR}/working || true
rm -r ${OUTPUT_DIR} || true

mkdir -p ${ROOT_DIR}/working
pushd ${ROOT_DIR}/working > /dev/null

install_dependencies
build_rootfs

tree -h $OUTPUT_DIR

popd > /dev/null
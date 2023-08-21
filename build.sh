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
#     mkdir -pv "$rootfs" "$OUTPUT_DIR"

#     cp -rvf $ROOT_DIR/overlay/* $rootfs
#     cp -v $ROOT_DIR/chroot.sh $PWD/

#     pushd $ROOT_DIR > /dev/null
#     docker build -t working-image .
#     popd > /dev/null

#     # curl -O https://cloud-images.ubuntu.com/minimal/releases/jammy/release/ubuntu-22.04-minimal-cloudimg-amd64-root.tar.xz
#     #
#     # TBD use systemd-nspawn instead of Docker
#     #   sudo tar xaf ubuntu-22.04-minimal-cloudimg-amd64-root.tar.xz -C $rootfs
#     #   sudo systemd-nspawn --resolv-conf=bind-uplink -D $rootfs
#     docker run --env rootfs=$rootfs --privileged --rm -i -v "$PWD:/work" -w /work working-image bash -s <<'EOF'

# ./chroot.sh

# # Copy everything we need to the bind-mounted rootfs image file
# dirs="bin etc home lib lib64 root sbin usr"
# for d in $dirs; do tar c "/$d" | tar x -C $rootfs; done

# # Make mountpoints
# mkdir -pv $rootfs/{dev,proc,sys,run,tmp,var/lib/systemd}
# EOF

#     # TBD what abt /etc/hosts?
#     echo |sudo tee $rootfs/etc/resolv.conf

    sudo debootstrap --arch=amd64 jammy $rootfs http://archive.ubuntu.com/ubuntu/
    cp -rvf $ROOT_DIR/overlay/* $rootfs

    # -comp zstd but guest kernel does not support
    rootfs_img="$OUTPUT_DIR/$ROOTFS_NAME.squashfs"
    sudo mv $rootfs/root/manifest $OUTPUT_DIR/$ROOTFS_NAME.manifest
    sudo mksquashfs $rootfs $rootfs_img -all-root -noappend
    sudo rm -rf $rootfs
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
#!/bin/bash
# see: https://github.com/firecracker-microvm/firecracker/blob/main/resources/rebuild.sh

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
    sudo apt install -y unzip squashfs-tools busybox-static tree cpio curl
}

function dir2ext4img {
    # ext4
    # https://unix.stackexchange.com/questions/503211/how-can-an-image-file-be-created-for-a-directory
    local DIR=$1
    local IMG=$2
    # Default size for the resulting rootfs image is 300M
    local SIZE=${3:-300M}
    local TMP_MNT=$(mktemp -d)
    truncate -s "$SIZE" "$IMG"
    mkfs.ext4 -F "$IMG"
    sudo mount "$IMG" "$TMP_MNT"
    sudo tar c -C $DIR . |sudo tar x -C "$TMP_MNT"
    # cleanup
    sudo umount "$TMP_MNT"
    rmdir $TMP_MNT
}

# Build a rootfs
function build_rootfs {
    local ROOTFS_NAME=ubuntu-22.04
    local rootfs="tmp_rootfs"
    mkdir -pv "$rootfs" "$OUTPUT_DIR"

    cp -rvf overlay/* $rootfs
    cp -v $ROOT_DIR/chroot.sh $ROOT_DIR/.bashrc $PWD/

    pushd $ROOT_DIR > /dev/null
    docker build -t working-image .
    popd > /dev/null

    # curl -O https://cloud-images.ubuntu.com/minimal/releases/jammy/release/ubuntu-22.04-minimal-cloudimg-amd64-root.tar.xz
    #
    # TBD use systemd-nspawn instead of Docker
    #   sudo tar xaf ubuntu-22.04-minimal-cloudimg-amd64-root.tar.xz -C $rootfs
    #   sudo systemd-nspawn --resolv-conf=bind-uplink -D $rootfs
    docker run --env rootfs=$rootfs --privileged --rm -i -v "$PWD:/work" -w /work working-image bash -s <<'EOF'

./chroot.sh

# Copy everything we need to the bind-mounted rootfs image file
dirs="bin etc home lib root sbin usr"
for d in $dirs; do tar c "/$d" | tar x -C $rootfs; done

# Make mountpoints
mkdir -pv $rootfs/{dev,proc,sys,run,tmp,var/lib/systemd}
EOF

    # TBD what abt /etc/hosts?
    echo |sudo tee $rootfs/etc/resolv.conf

    # -comp zstd but guest kernel does not support
    rootfs_img="$OUTPUT_DIR/$ROOTFS_NAME.squashfs"
    sudo mv $rootfs/root/manifest $OUTPUT_DIR/$ROOTFS_NAME.manifest
    sudo mksquashfs $rootfs $rootfs_img -all-root -noappend
    rootfs_ext4=$OUTPUT_DIR/$ROOTFS_NAME.ext4
    dir2ext4img $rootfs $rootfs_ext4
    sudo rm -rf $rootfs
    sudo chown -Rc $USER. $OUTPUT_DIR
}

function get_firecracker_resources() {
    # Download the latest Firecracker resources. We use everything except their build.sh.
    firecracker_version=$(cat "${ROOT_DIR}/versions/firecracker")

    curl --fail -OL https://github.com/firecracker-microvm/firecracker/archive/${firecracker_version}.zip

    unzip -q -o ${firecracker_version}.zip
    rm ${firecracker_version}.zip

    mv firecracker-${firecracker_version}/resources/* ./
    rm -r firecracker-${firecracker_version}
}

#### main ####

rm -r ${ROOT_DIR}/working || true
rm -r ${OUTPUT_DIR} || true

mkdir -p ${ROOT_DIR}/working
pushd ${ROOT_DIR}/working > /dev/null

install_dependencies
get_firecracker_resources

build_rootfs

tree -h $OUTPUT_DIR

popd > /dev/null
#!/bin/bash

set -eux -o pipefail

function download() {
    local destination="$1"
    local image_name=$(basename "$destination")

    local checksum_path="${destination}.sha256.txt"
    local checksum_name=$(basename "$checksum_path")

    # If image exists, check checksum
    if [ -f "$destination" ]; then
        wget -O "$checksum_path" "https://github.com/firecracker-github-runner/ubuntu-rootfs/releases/latest/download/${checksum_name}"

        local checksum=$(cat "$checksum_path" | awk '{print $1}')
        local checksum_local=$(sha256sum "$destination" | awk '{print $1}')
        if [ "$checksum" == "$checksum_local" ]; then
            echo "image checksum match, skip download"
            return
        fi
    fi

    wget -O "$destination" "https://github.com/firecracker-github-runner/ubuntu-rootfs/releases/latest/download/${image_name}"
}

function launch() {
    local variant="$1"

    pushd $(dirname $0) >/dev/null

    local image_path="images/ubuntu-${variant}-24.04.squashfs"
    mkdir -p "images"

    download "$image_path"

    local kernel_params=""

    # see: https://jonathanwoollett-light.github.io/firecracker/book/book/network-setup.html
    local tap_device="tap0"
    local gateway_ip=$(ip route | grep default | awk '{print $3}')
    local mac_address="$(ip a | grep -A1 ${tap_device} | grep ether | awk '{print $2}')"

    #add ip kernel param: guest-ip:[server-ip]:gateway-ip:netmask:hostname:iface:state
    ip="172.16.0.2"
    gateway_ip="172.16.0.1"
    hostname="ubuntu-1"
    mask="255.255.255.252" #/30
    kernel_params="${kernel_params} ip=${ip}::${gateway_ip}:${mask}:${hostname}:eth0:up"

    # if variant is "runner", add kernel opt

    if [ "$variant" == "runner" ]; then
        kernel_params="${kernel_params} systemd.unit=firecracker.target"
    fi

    local systemd_masks=""
    # add systemd mask kernel params, e.g. systemd.mask=systemd-networkd.service
    for mask in $systemd_masks; do
        kernel_params="${kernel_params} systemd.mask=${mask}"
    done

    firectl -t -c 2 \
        --kernel='vmlinux' \
        --root-drive="${image_path}:ro" \
        --kernel-opts="${kernel_params} init=/sbin/overlay-init iommu=off net.ifnames=0 console=ttyS0 noapic acpi=off reboot=k panic=1 pci=off nomodules systemd.journald.forward_to_console i8042.noaux i8042.nomux i8042.nopnp i8042.dumbkbd selinux=0" \
        --tap-device="${tap_device}/${mac_address}" \
        --metadata='{"test":true}' \
        --cpu-template=C3 \
        --debug

    popd >/dev/null
}

launch "$@"

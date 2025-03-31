#!/bin/bash

set -eux -o pipefail

# For UFW:
# ensure `DEFAULT_FORWARD_POLICY="ACCEPT"` in /etc/default/ufw

function setup {
  local out_if=enp4s0
  local tap_if=tap0
  local gateway=172.16.0.1
  local ip=172.16.0.2

  sudo sysctl -w net.ipv4.ip_forward=1

  sudo ip tuntap add $tap_if mode tap
  sudo ip addr add ${gateway}/30 dev $tap_if
  sudo ip link set $tap_if up

  sudo nft add table firecracker
  sudo nft 'add chain firecracker postrouting { type nat hook postrouting priority srcnat; policy accept; }'
  sudo nft 'add chain firecracker filter { type filter hook forward priority filter; policy accept; }'

  sudo nft add rule firecracker postrouting ip saddr $ip oifname $out_if counter masquerade

  sudo nft add rule firecracker filter iifname $tap_if oifname $out_if accept
  sudo nft add rule firecracker filter oifname $tap_if iifname $out_if ct state related,established accept
}

setup "$@"


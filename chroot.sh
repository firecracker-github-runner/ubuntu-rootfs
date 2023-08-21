#!/bin/bash

set -eu -o pipefail
set -x

cd $(dirname $0)

# add user
passwd -d root
useradd -s /bin/bash -G sudo -G 0 -M -d /working runner
chmod g+rwx /working
echo "runner:runner" | chpasswd
echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

apt install -y --no-install-recommends localepurge
localepurge -v
apt remove -y --purge --auto-remove localepurge
apt clean

# clean up unneeded things
rm -vf /etc/systemd/system/timers.target.wants/*
systemctl disable e2scrub_reap.service
rm -r /home
rm -r /media
rm -r /root


cat >> /etc/sysctl.conf <<EOF
# This avoids a SPECTRE vuln
kernel.unprivileged_bpf_disabled=1
EOF

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

# clean up unneeded things
rm -vf /etc/systemd/system/timers.target.wants/*
systemctl disable e2scrub_reap.service
rm -r /home
rm -r /media
rm -r /root

rm -f /etc/systemd/system/multi-user.target.wants/systemd-resolved.service
rm -f /etc/systemd/system/dbus-org.freedesktop.resolve1.service
rm -f /etc/systemd/system/sysinit.target.wants/systemd-timesyncd.service
rm -vf /etc/systemd/system/timers.target.wants/*

cat >> /etc/sysctl.conf <<EOF
# This avoids a SPECTRE vuln
kernel.unprivileged_bpf_disabled=1
EOF

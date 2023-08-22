#!/bin/bash

set -eu -o pipefail
set -x

cd $(dirname $0)

passwd -d root

# clean up unneeded things
rm -vf /etc/systemd/system/timers.target.wants/*
systemctl disable e2scrub_reap.service
rm -r /home
rm -r /media

rm -f /etc/systemd/system/multi-user.target.wants/systemd-resolved.service
rm -f /etc/systemd/system/dbus-org.freedesktop.resolve1.service
rm -f /etc/systemd/system/sysinit.target.wants/systemd-timesyncd.service
rm -vf /etc/systemd/system/timers.target.wants/*

cat >> /etc/sysctl.conf <<EOF
# This avoids a SPECTRE vuln
kernel.unprivileged_bpf_disabled=1
EOF

dpkg-query --show > /root/manifest

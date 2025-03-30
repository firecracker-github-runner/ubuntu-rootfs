#!/bin/bash

set -eux -o pipefail

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

cat >>/etc/sysctl.conf <<EOF
# This avoids a SPECTRE vuln
kernel.unprivileged_bpf_disabled=1
EOF

systemd-machine-id-setup --print
rm /var/lib/dbus/machine-id || true
ln -s /etc/machine-id /var/lib/dbus/machine-id

# This gets pulled out by the build script
dpkg-query --show >/root/manifest

#!/bin/bash

set -eux -o pipefail

cd $(dirname $0)

passwd -d root

# clean up unneeded things
rm -r /home
rm -r /media

rm -r /etc/systemd/system/getty.target.wants
rm -r /etc/systemd/system/multi-user.target.wants
rm -r /etc/systemd/system/sysinit.target.wants
rm -r /etc/systemd/system/timers.target.wants

# see: https://bugs.launchpad.net/ubuntu/+source/shadow/+bug/2060676
sed -i -e '/ pam_lastlog.so$/s/^/# /' /etc/pam.d/login

truncate -s 0 /etc/machine-id
rm /var/lib/dbus/machine-id || true
ln -s /etc/machine-id /var/lib/dbus/machine-id

# This gets pulled out by the build script
dpkg-query --show >/root/manifest

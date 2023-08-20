#!/bin/bash

set -eu -o pipefail
set -x
PS4='+\t '

cp -ruv $rootfs/* /

packages="udev systemd-sysv iproute2 curl socat python3-minimal iperf3 iputils-ping kmod git"

export DEBIAN_FRONTEND=noninteractive
apt update
apt install -y --no-install-recommends $packages
apt autoremove

# Set a hostname.
echo "ubuntu-runner" > /etc/hostname

passwd -d root

# The serial getty service hooks up the login prompt to the kernel console
# at ttyS0 (where Firecracker connects its serial console). We'll set it up
# for autologin to avoid the login prompt.
for console in ttyS0; do
    mkdir "/etc/systemd/system/serial-getty@$console.service.d/"
    cat <<'EOF' > "/etc/systemd/system/serial-getty@$console.service.d/override.conf"
[Service]
# systemd requires this empty ExecStart line to override
ExecStart=
ExecStart=-/sbin/agetty --autologin root -o '-p -- \\u' --keep-baud 115200,38400,9600 %I dumb
EOF
done

# Disable resolved and ntpd
#
rm -f /etc/systemd/system/multi-user.target.wants/systemd-resolved.service
rm -f /etc/systemd/system/dbus-org.freedesktop.resolve1.service
rm -f /etc/systemd/system/sysinit.target.wants/systemd-timesyncd.service

# make /tmp a tmpfs
ln -s /usr/share/systemd/tmp.mount /etc/systemd/system/tmp.mount
systemctl enable tmp.mount

# don't need this
systemctl disable e2scrub_reap.service
rm -vf /etc/systemd/system/timers.target.wants/*

systemctl enable var-lib-systemd.mount

#### trim image https://wiki.ubuntu.com/ReducingDiskFootprint
# this does not save much, but oh well
rm -rf /usr/share/{doc,man,info,locale}

cat >> /etc/sysctl.conf <<EOF
# This avoids a SPECTRE vuln
kernel.unprivileged_bpf_disabled=1
EOF

# Install bashrc
mv /root/.bashrc /root/.bashrc.orig
cp ./.bashrc /root/.bashrc

# Build a manifest
dpkg-query --show > /root/manifest

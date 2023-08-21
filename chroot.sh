#!/bin/bash

set -eu -o pipefail
set -x

cd $(dirname $0)

apt update
apt upgrade -y
apt install -y --no-install-recommends wget curl
apt clean

# add user
passwd -d root
useradd -m -s /bin/bash -G sudo runner
echo "runner:runner" | chpasswd
echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
#!/bin/bash

set -eux -o pipefail

cd $(dirname $0)

mkdir -p "/working"

# add user
useradd -s /bin/bash -G sudo -G 0 -M -d /working runner
passwd -d runner
chmod g+rwx /working
echo "runner ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers

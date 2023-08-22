#!/bin/bash

set -eu -o pipefail
set -x

cd $(dirname $0)

# add user
passwd -d root
useradd -s /bin/bash -G sudo -G 0 -M -d /working runner
passwd -d runner
chmod g+rwx /working
echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

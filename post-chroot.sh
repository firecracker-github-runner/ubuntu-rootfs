#!/bin/bash

# This script runs inside of the container after the default setup has been applied.

set -eu -o pipefail
set -x

function install_dependencies() {
    export DEBIAN_FRONTEND=noninteractive
    apt install -y --no-install-recommends git
    apt autoremove
}

function install_bashrc() {
    cat <<'EOF' 
set -e
echo "Welcome to the container!"
reboot
EOF >> /root/.bashrc
}

function main() {
    install_dependencies
    install_bashrc
}

main "$@"
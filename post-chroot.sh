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
    mv /root/.bashrc /root/.bashrc.orig
    cp ./.bashrc /root/.bashrc
}

function main() {
    install_dependencies
    install_bashrc
}

main "$@"
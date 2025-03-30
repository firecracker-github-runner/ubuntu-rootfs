#! /bin/bash

set -eux -o pipefail

docker buildx build --platform linux/amd64 . -t firecracker-ubuntu-rootfs-working

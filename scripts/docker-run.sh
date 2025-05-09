#! /bin/bash

set -eux -o pipefail

function main {
  local extra_args="$@"

  mkdir -p ./dist
  mkdir -p ./working
  chmod a+rw ./dist
  chmod a+rw ./working

  docker run -it --rm \
    --cap-add=SYS_ADMIN \
    -v ./working:/working/working:rw \
    -v ./variants:/working/variants:ro \
    -v ./build.sh:/working/build.sh:ro \
    -v ./SOURCE_DATE_EPOCH:/working/SOURCE_DATE_EPOCH:ro \
    -v ./dist:/working/dist:rw \
    $extra_args \
    firecracker-ubuntu-rootfs-working
}

main "$@"

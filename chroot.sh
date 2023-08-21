#!/bin/bash

set -eu -o pipefail
set -x

cd $(dirname $0)

apt update
apt upgrade -y
apt install -y --no-install-recommends wget curl
apt clean

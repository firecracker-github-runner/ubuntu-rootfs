#!/bin/bash

set -eu -o pipefail
set -x
set -m

echo "INIT!"

su -c 'echo "nameserver 1.1.1.1" > /etc/resolv.conf'

curl https://google.com

#!/bin/bash

set -eu -o pipefail
set -x

echo "INIT!"

id -n

curl https://google.com

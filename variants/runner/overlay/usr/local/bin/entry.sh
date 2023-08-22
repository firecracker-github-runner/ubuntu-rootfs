#!/bin/bash

set -eu -o pipefail
set -x

echo "INIT!"

id

curl https://google.com

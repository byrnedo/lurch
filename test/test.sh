#!/bin/bash

set -euo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#curl -L https://github.com/aelsabbahy/goss/releases/download/v0.3.6/goss-linux-amd64 -o ~/Downloads/goss-linux-amd64

#export GOSS_PATH=~/Downloads/goss-linux-amd64

function echoH() {
echo
echo "########################"
echo "%%%% $1"
echo "########################"
echo
}

set +e
mkdir -p ./tmp/certs
set -e

cd ./tmp/certs

echoH "Making test cert"
$DIR/scripts/make-cert.sh foo.bar
$DIR/scripts/make-cert.sh foo.bar2

cd -

echoH "Running Dgoss"
dgoss run \
    -v $PWD/tmp/certs/foo.bar:/usr/local/openresty/nginx/ssl/foo.bar/ \
    -v $PWD/tmp/certs/foo.bar2:/usr/local/openresty/nginx/ssl/foo.bar2/ \
    test



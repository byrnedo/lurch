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

function errReport() {
  local err=$?
  set +o xtrace
  echo >&2 "Error in ${BASH_SOURCE[1]}:${BASH_LINENO[0]}. '${BASH_COMMAND}' exited with status $err"
}

function cleanup(){
    echoH "Cleaning up"
    set +e
    x=$(docker rm -f echo)
    x=$(docker network rm test-openresty-proxy)
    set -e
}

IMAGE_ID=$(cd $DIR/../ && docker build -q .)

trap "{ errReport $LINENO; cleanup; }" ERR

trap "{ cleanup; }" SIGINT SIGTERM

set +e
mkdir -p ./tmp/certs
set -e

cd ./tmp/certs

echoH "Making test cert"
$DIR/scripts/make-cert.sh foo.bar www.foo.bar
$DIR/scripts/make-cert.sh foo.bar2 www.foo.bar2

cd -

echoH "Creating user defined network"
set +e
docker network create test-openresty-proxy
set -e

APPS_JSON=$(cat ./apps.json)
echoH "Running Dgoss"


ECHO_ID=$(docker run --name echo --network test-openresty-proxy -d hashicorp/http-echo -listen=:80 -text="hello world")

dgoss run --rm -it \
    --network test-openresty-proxy \
    --add-host foo.bar:127.0.0.1 \
    --add-host foo.bar2:127.0.0.1 \
    --add-host www.foo.bar:127.0.0.1 \
    --add-host www.foo.bar2:127.0.0.1 \
    -e APPS_CONFIG_JSON="$APPS_JSON" \
    -v $PWD/tmp/certs/foo.bar:/usr/local/openresty/nginx/ssl/foo.bar/ \
    -v $PWD/tmp/certs/foo.bar2:/usr/local/openresty/nginx/ssl/foo.bar2/ \
    $IMAGE_ID

cleanup

exit 0

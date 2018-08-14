#!/bin/bash
set -euo pipefail

function join_by { local IFS="$1"; shift; echo "$*"; }

if [ $# -lt 1 ]; then
    echo >&1 "usage: $0 DOMAIN [DOMAIN2] [DOMAIN3]"
    exit 1
fi

DOMAIN=${1}

SANS=()
for i in "$@"; do 
    SANS+=("DNS:${i}")
done

SAN_JOINED=$(join_by "," "${SANS[@]}")

set +e 
mkdir -p ./$DOMAIN
set -e
echo $SAN_JOINED
openssl req -new -x509 -reqexts SAN -nodes -out ./$DOMAIN/server.crt -keyout ./$DOMAIN/server.key -subj "/C=SE/L=Gothenburg/O=FoobarInc Network/OU=IT Department/CN=$DOMAIN" -reqexts SAN -config <(cat /etc/ssl/openssl.cnf <(printf "\n[SAN]\nsubjectAltName=$SAN_JOINED")) 

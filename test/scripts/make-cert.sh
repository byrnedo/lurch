#!/bin/bash
set -euo pipefail

if [ $# -lt 1 ]; then
    echo >&1 "usage: $0 DOMAIN"
    exit 1
fi

DOMAIN=${1}
set +e 
mkdir -p ./$DOMAIN
set -e
openssl req -new -x509 -nodes -out ./$DOMAIN/server.crt -keyout ./$DOMAIN/server.key -subj "/C=SE/ST=/L=Gothenburg/O=FoobarInc Network/OU=IT Department/CN=$DOMAIN"

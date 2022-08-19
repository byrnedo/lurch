#!/bin/sh
set -eu

GOMP_DIR=${GOMP_DIR:-/etc/gomplate}
TEMPLATE_PATH="$GOMP_DIR/nginx.conf.tmpl"
APP_CONFIG_PATH="$GOMP_DIR/data/apps.json"
CONF_PATH="/usr/local/openresty/nginx/conf/nginx.conf"
APPS_CONFIG_JSON=${APPS_CONFIG_JSON:-}


# If config supplied as env then write the file
if [ -n "$APPS_CONFIG_JSON" ]; then
    echo "$APPS_CONFIG_JSON" > "$APP_CONFIG_PATH"
fi

## Chown storage of ssl certs
mkdir -p /etc/resty-auto-ssl/storage
chown -R nobody /etc/resty-auto-ssl/storage

## Hopefully fix bug
rm -f auto-ssl-sockproc.pid

# Template nginx config
/usr/local/bin/gomplate -d apps="$APP_CONFIG_PATH" --file "$TEMPLATE_PATH" --out $CONF_PATH

nginxfmt -v $CONF_PATH

# Test config
if ! /usr/local/openresty/bin/openresty -c $CONF_PATH -t; then
  cat --number $CONF_PATH
  exit 1
fi

exec /usr/local/openresty/bin/openresty -c $CONF_PATH -g "daemon off;"

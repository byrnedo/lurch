#!/bin/sh
set -eu

GOMP_DIR=${GOMP_DIR:-/etc/gomplate}

# the nginx configuration template
TEMPLATE_PATH="$GOMP_DIR/nginx.conf.tmpl"

# the apps json config path if local
DEFAULT_APPS_CONFIG_PATH="$GOMP_DIR/data/apps.json"

# the user supplied apps json config path, defaults to local
APPS_CONFIG_PATH=${APPS_CONFIG_PATH:-${DEFAULT_APPS_CONFIG_PATH}}

# the path openresty will look for the nginx config
CONF_PATH="/usr/local/openresty/nginx/conf/nginx.conf"

APPS_CONFIG_JSON=${APPS_CONFIG_JSON:-}

# If config supplied as env then write the file locally
if [ -n "$APPS_CONFIG_JSON" ]; then
  echo "$APPS_CONFIG_JSON" >"$DEFAULT_APPS_CONFIG_PATH"
fi

## Chown storage of ssl certs
mkdir -p /etc/resty-auto-ssl/storage
chown -R nobody /etc/resty-auto-ssl/storage

## Hopefully fix bug
rm -f auto-ssl-sockproc.pid

SYSTEM_RESOLVER=$(cat /etc/resolv.conf | grep -im 1 '^nameserver' | cut -d ' ' -f2)
export SYSTEM_RESOLVER

# template the nginx config, format it and test it, printing the config to stdout if there's an error
make_config() {
  # Template nginx config
  mv $CONF_PATH ${CONF_PATH}.old
  /usr/local/bin/gomplate -d apps="$APPS_CONFIG_PATH" --file "$TEMPLATE_PATH" --out $CONF_PATH

  # Format it
  nginxfmt -v $CONF_PATH

  # Test config
  if ! /usr/local/openresty/bin/openresty -c $CONF_PATH -t; then
    cat --number $CONF_PATH
    mv ${CONF_PATH}.old $CONF_PATH
    exit 1
  fi
}

# hack to wait for pid to appear
wait_file_changed() {
  tail -fn0 "$1" | head -n1
}

pidfile=/usr/local/openresty/nginx/logs/nginx.pid

make_config

/usr/local/openresty/bin/openresty -c $CONF_PATH -g "daemon off;" &

trap 'echo kill signal received; kill "$pid"' INT TERM
trap 'echo reload signal received!; make_config; kill -HUP $pid; wait "$pid"' HUP

echo 'waiting for pid to appear...'
wait_file_changed $pidfile
echo 'pid found.'
pid="$(cat $pidfile)"

wait $pid

#!/bin/bash
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


pidfile=/usr/local/openresty/nginx/logs/nginx.pid

ensure_self_signed() {
  domain=$1
  ssl_path="/usr/local/openresty/nginx/ssl/${domain}"
  if [ ! -d "$ssl_path" ]; then
    echo "generating self signed cert for $domain"
    mkdir -p $ssl_path
    country=SE
    state=Kalmar
    city=Kalmar
    # This line generates a self signed SSL certificate and key without user intervention.
    openssl req -x509 -newkey rsa:4096 -keyout "${ssl_path}/server.key" -out "${ssl_path}/server.crt" \
      -days 365 -nodes -subj "/C=$country/ST=$state/L=$city/O=Internet/OU=./CN=$domain/emailAddress=postmaster@$domain"
  fi
}

kill_child() {
  pid="$(cat $pidfile 2>/dev/null || echo '')"
  if [ -n "${pid:-}" ]; then
    echo "killing child pid $pid"
    kill "$pid"
    wait "$pid"
  fi
}

trap 'echo kill signal received; kill_child' INT TERM QUIT


## Chown storage of ssl certs
mkdir -p /etc/resty-auto-ssl/storage
chown -R nobody /etc/resty-auto-ssl/storage

## Hopefully fix bug
rm -f auto-ssl-sockproc.pid

SYSTEM_RESOLVER=$(cat /etc/resolv.conf | grep -im 1 '^nameserver' | cut -d ' ' -f2)
export SYSTEM_RESOLVER

# template the nginx config, format it and test it, printing the config to stdout if there's an error
make_config() {
  echo "templating..."
  mv $CONF_PATH ${CONF_PATH}.old
  /usr/local/bin/gomplate -d apps="$APPS_CONFIG_PATH" --file "$TEMPLATE_PATH" --out $CONF_PATH

  # all good, ensure self signed cert exists for base url
  domains=$(grep "# anchor::domain" "$CONF_PATH" | awk '{print $3}' | sort -u)
  for domain in $domains; do
    ensure_self_signed $domain
  done

  # Format it
  echo "formatting..."
  nginxfmt -v $CONF_PATH

  # Test config
  echo "testing config..."
  if ! /usr/local/openresty/bin/openresty -c $CONF_PATH -t; then
    cat --number $CONF_PATH
    # restore prev config
    mv ${CONF_PATH}.old $CONF_PATH
  fi

}

# hack to wait for pid to appear
wait_file_changed() {
  tail -fn0 "$1" | head -n1 >/dev/null 2>&1
}

reload_and_wait() {
  # lock
  if {
    set -C
    2>/dev/null >/tmp/lurchreload.lock
  }; then
    # have lock
    pid="$(cat $pidfile 2>/dev/null || echo '')"
    if [ -z "${pid:-}" ]; then
      return
    fi

    make_config
    echo "sending HUP..."
    kill -HUP "$pid"
    # release
    rm /tmp/lurchreload.lock
    echo "waiting on $pid"
    wait "$pid"
  fi
}

make_config

echo "staring daemon..."
/usr/local/openresty/bin/openresty -c $CONF_PATH -g "daemon off;" &

trap 'reload_and_wait' HUP

echo 'waiting for pid to appear...'
wait_file_changed $pidfile
pid="$(cat $pidfile)"
echo "master process pid found ($pid)"

echo "waiting on process"
wait $pid

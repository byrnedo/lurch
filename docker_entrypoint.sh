#!/bin/sh

GOMP_DIR=${GOMP_DIR:-/etc/gomplate}

template="$GOMP_DIR/nginx.conf.tmpl"

app_config="$GOMP_DIR/data/apps.json"

conf_path="/usr/local/openresty/nginx/conf/nginx.conf"

# If template supplied as env then write the file
if [ ! -z "$NGINX_TEMPLATE" ]; then
    echo "$NGINX_TEMPLATE" > $template
fi

# If config supplied as env then write the file
if [ ! -z "$APPS_CONFIG_JSON" ]; then
    echo "$APPS_CONFIG_JSON" > $app_config
fi

## Chown storage of ssl certs
chown -R nobody /etc/resty-auto-ssl/storage

## Hopefully fix bug
rm -f auto-ssl-sockproc.pid

# Template nginx config
/usr/local/bin/gomplate -d apps=$app_config --file $template --out $conf_path && \

# Test config
/usr/local/openresty/bin/openresty -c $conf_path -t && \
exec /usr/local/openresty/bin/openresty -c $conf_path -g "daemon off;"

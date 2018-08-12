#!/bin/sh

GOMP_DIR=${GOMP_DIR:-/etc/gomplate}

template="$GOMP_DIR/nginx.conf.tmpl"

node_config="$GOMP_DIR/data/nodes.json"
app_config="$GOMP_DIR/data/apps.json"


conf_path="/usr/local/openresty/nginx/conf/nginx.conf"

if [ ! -z "$NGINX_TEMPLATE" ]; then
    echo "$NGINX_TEMPLATE" > $template
fi

if [ ! -z "$APPS_CONFIG_JSON" ]; then
    echo "$APPS_CONFIG_JSON" > $app_config
fi


if [ ! -z "$NODES_CONFIG_JSON" ]; then
    echo "$NODES_CONFIG_JSON" > $node_config
fi

chown -R nobody /etc/resty-auto-ssl/storage

rm -f auto-ssl-sockproc.pid

/usr/local/bin/gomplate -d apps=$app_config -d nodes=$node_config --file $template --out $conf_path && \
/usr/local/openresty/bin/openresty -c $conf_path -t && \
exec /usr/local/openresty/bin/openresty -c $conf_path -g "daemon off;"

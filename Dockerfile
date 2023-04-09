FROM --platform=linux/amd64 openresty/openresty:1.21.4.1-6-bullseye-fat
MAINTAINER Donal Byrne <byrnedo@tcd.ie>

ENV RESTY_AUTO_SSL_VERSION=0.13.1
ENV GOMPLATE_VERSION=v3.11.2
ENV RESTY_ROOT=/usr/local/openresty


RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    build-essential \
    curl \
    unzip \
    make \
    python3 && \
    rm -rf /var/lib/apt/lists/* && \
    curl -L https://luarocks.org/releases/luarocks-2.0.13.tar.gz --output /tmp/luarocks-2.0.13.tar.gz && \
        cd /tmp && \
        tar -xzvf luarocks-2.0.13.tar.gz && \
        cd luarocks-2.0.13/ && \
        ./configure --prefix=/usr/local/openresty/luajit \
            --with-lua=/usr/local/openresty/luajit/ \
            --lua-suffix=jit \
            --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 && \
        make && \
        make install && \
    DEBIAN_FRONTEND=noninteractive /usr/local/openresty/luajit/bin/luarocks install lua-resty-http && \
    DEBIAN_FRONTEND=noninteractive /usr/local/openresty/luajit/bin/luarocks install lua-resty-auto-ssl $RESTY_AUTO_SSL_VERSION && \
    opm get bungle/lua-resty-template && \
    curl -L https://github.com/hairyhenderson/gomplate/releases/download/$GOMPLATE_VERSION/gomplate_linux-amd64 > /tmp/gomplate && \
    mv /tmp/gomplate /usr/local/bin && \
    chmod +x /usr/local/bin/gomplate && \
    mkdir /etc/resty-auto-ssl && \
    chown nobody /etc/resty-auto-ssl && \
    curl -L https://raw.githubusercontent.com/slomkowski/nginx-config-formatter/master/nginxfmt.py > /usr/local/bin/nginxfmt && \
    chmod +x /usr/local/bin/nginxfmt

COPY docker_entrypoint.sh /docker_entrypoint.sh

RUN mkdir $RESTY_ROOT/nginx/conf.d/

COPY data /etc/gomplate/data
COPY nginx.conf.tmpl /etc/gomplate/nginx.conf.tmpl

COPY lua $RESTY_ROOT/nginx/lua


ENTRYPOINT ["/docker_entrypoint.sh"]


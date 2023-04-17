FROM --platform=linux/amd64 openresty/openresty:1.21.4.1-6-bullseye-fat
MAINTAINER Donal Byrne <byrnedo@tcd.ie>

ENV RESTY_AUTO_SSL_VERSION=0.13.1
ENV GOMPLATE_VERSION=v3.11.2
ENV HURL_VERSION=2.0.1
ENV RESTY_ROOT=/usr/local/openresty

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update -qq && \
    curl --location https://github.com/Orange-OpenSource/hurl/releases/download/${HURL_VERSION}/hurl_${HURL_VERSION}_$(dpkg --print-architecture).deb --output "/tmp/hurl.deb" && \
    DEBIAN_FRONTEND=noninteractive apt install -y /tmp/hurl.deb && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    build-essential \
    curl \
    unzip \
    make \
    bsdmainutils \
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
    curl -L https://github.com/hairyhenderson/gomplate/releases/download/$GOMPLATE_VERSION/gomplate_linux-$(dpkg --print-architecture) > /tmp/gomplate && \
    mv /tmp/gomplate /usr/local/bin && \
    chmod +x /usr/local/bin/gomplate && \
    mkdir /etc/resty-auto-ssl && \
    chown nobody /etc/resty-auto-ssl && \
    curl -L https://raw.githubusercontent.com/slomkowski/nginx-config-formatter/master/nginxfmt.py > /usr/local/bin/nginxfmt && \
    chmod +x /usr/local/bin/nginxfmt && \
    curl -L https://raw.githubusercontent.com/dehydrated-io/dehydrated/v0.7.1/dehydrated > /usr/local/openresty/luajit/bin/resty-auto-ssl/dehydrated && \
    chmod +x /usr/local/openresty/luajit/bin/resty-auto-ssl/dehydrated

COPY docker_entrypoint.sh /docker_entrypoint.sh

RUN mkdir $RESTY_ROOT/nginx/conf.d/

COPY default-apps.yaml /etc/lurch/apps.yaml
COPY nginx.conf.tmpl /etc/lurch/
COPY error.html /etc/lurch/
COPY test/ /etc/lurch/test


COPY lua $RESTY_ROOT/nginx/lua


ENTRYPOINT ["/docker_entrypoint.sh"]


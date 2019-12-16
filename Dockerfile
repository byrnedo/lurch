FROM openresty/openresty:1.11.2.4-trusty
MAINTAINER Donal Byrne <byrnedo@tcd.ie>

ENV RESTY_AUTO_SSL_VERSION=0.11.1-1
ENV GOMPLATE_VERSION=v1.9.1
ENV RESTY_ROOT=/usr/local/openresty


RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    unzip && \
    rm -rf /var/lib/apt/lists/* && \
    DEBIAN_FRONTEND=noninteractive /usr/local/openresty/luajit/bin/luarocks install lua-resty-http && \
    DEBIAN_FRONTENT=noninteractive /usr/local/openresty/luajit/bin/luarocks install lua-resty-auto-ssl $RESTY_AUTO_SSL_VERSION && \
    opm get bungle/lua-resty-template && \
    curl -L https://github.com/hairyhenderson/gomplate/releases/download/$GOMPLATE_VERSION/gomplate_linux-amd64 > /tmp/gomplate && \
    mv /tmp/gomplate /usr/local/bin && \
    chmod +x /usr/local/bin/gomplate && \
    mkdir /etc/resty-auto-ssl && \
    chown nobody /etc/resty-auto-ssl

COPY docker_entrypoint.sh /docker_entrypoint.sh

RUN mkdir $RESTY_ROOT/nginx/conf.d/

COPY data /etc/gomplate/data
COPY nginx.conf /etc/gomplate/nginx.conf.tmpl

COPY error.include $RESTY_ROOT/nginx/conf.d/error.include
COPY ssl.include $RESTY_ROOT/nginx/conf.d/ssl.include

#ADD ./certs $RESTY_ROOT/nginx/ssl

#RUN rm -rf $RESTY_ROOT/nginx/html
#COPY html $RESTY_ROOT/nginx/html
COPY lua $RESTY_ROOT/nginx/lua


ENTRYPOINT ["/docker_entrypoint.sh"]


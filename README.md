## Openresty Proxy

Nginx proxy app which reads a data source and generates a new nginx conf for each service

One file is read.

This is placed in `/etc/gomplate/data/apps.json`

They can be overridden with envs:

- APPS_CONFIG_JSON

This lb assumes the docker swarm mode internal load balancing system where a service has
1 public port spread across every machine in cluster.

- APPS Config looks like this:

```
 {
    "defaultBaseUrl": "local.foo.bar",
    "workerConnections": 1024, # default is 1024 if not supplied
    "proxyReadTimeout": 120, # default is 120 if not supplied
    "proxySendTimeout": 120, # default is 120 if not supplied
    "sendTimeout": 120, # default is 120 if not supplied
    "readTimeout": 120, # default is 120 if not supplied
    "services": [
        {
            "name": "my-service",
            "subdomains": [
                {
                    "name": "www",
                    "enabled": "true",
                    "enableClientCerts": false,
                    "enableSsl": true,
                    "baseUrl": "local.foo.bar"
                }
            ],
            "origin": {
                "type": "remote",
                "port": 9111,
                "host": "app.upstream.com"
            }
        }
    ]
}
```

**An app can have multiple subdomains**

Top level options

    |Service options      |Required|Default|Description                                      |
    |----------------------------------------------------------------------------------------|
    |`defaultBaseUrl`     |true    |       |Base url for not found ssl certs etc             |
    |`workerConnections`  |false   |   1024|No of worker connections                         |
    |`proxyReadTimeout`   |false   |    120|Read timeout to upstream                         |
    |`proxySendTimeout`   |false   |    120|Send timeout to upstream                         |
    |`sendTimeout`        |false   |    120|Send timeout                                     |
    |`readTimeout`        |false   |    120|Read timeout                                     |
    |`authRequestRedirect`|false   |       |Where to redirect to if auth request fails       |
    |`authRequestUpstream`|false   |       |Where to send auth requests to                   |
    |`authRequestCookie`  |false   |       |Name of cookie to take bearer token from         |

`service` options

    |Service options      |Required|Default|Description                                      |
    |----------------------------------------------------------------------------------------|
    |`name`               |true    |       |The service name                                 |
    |`subdomains`         |true    |       |The subdomains for the service                   |
    |`origin`           |true    |       |The origin settings for the service            |

`subdomain` options explained

    |Subdomain options    |Required|Default|Description                                      |
    |----------------------------------------------------------------------------------------|
    |`name`               |true    |       |The subdommain                                   |
    |`enabled`            |true    |       |Whether or not the domain is visible             |
    |`enableSsl`          |true    |       |Whether or not to apply ssl server side          |
    |`enableLetsEncrypt`  |false   |false  |Whether or not to apply auto ssl                 |
    |`enableSso`          |false   |false  |Whether or not to shield with single-sign-on     |
    |`enableClientCerts`  |true    |       |Whether or not to require client ssl cert as well|
    |`baseUrl`            |true    |       |Base domain for the sub domain                   |
    |`port`               |false   |443    |The port to listen on publicly for this domain   |
    |`clientMaxBodySize`  |false   |20m    |Max upload body size                             |

`origin` options

If `origin.type = "remote"`

    |Remote options      |Required|Default|Description                                     |
    |----------------------------------------------------------------------------------------|
    |`host`                |true    |       |The host to proxy to                            |
    |`port`                |true    |       |The port to proxy to                            |

If `origin.type = "local"`

    |Remote options      |Required|Default|Description                                     |
    |----------------------------------------------------------------------------------------|
    |`root`                |true    |       |The root dir where the files are hosted                            |

NOTE: A subdomain of 'www' also will be available at 'foo.bar' or whatever the base-url is set to.

# SSL Defaults

A default certificate needs to be supplied, even when using letsencrypt.

These must be named `server.crt` and placed in `/usr/local/openresty/nginx/ssl/<baseUrl>/`.

So generate a self-signed one for worst case and mount it in :)
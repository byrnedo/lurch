## Lurch

<p align="center">
    <img src="./lurch.jpg" alt="Lurch" width="200">
 </p>


Openresty proxy with following features:

- LetsEncrypt HTTPS
- SSO via nginx auth requests
- Simple static site hosting (with optional path proxying)
- Dynamic config updates via Gomplate remote datasources

Docker image available on [docker hub](https://hub.docker.com/r/byrnedo/lurch).

### Config

The nginx config is generated from the json structure using [Gomplate.](https://docs.gomplate.ca)

Gomplate supports many kinds of [datasources](https://docs.gomplate.ca/datasources/) ( local file, remote file over
http, git, you name it!).

By default the proxy expects the json file at `/etc/gomplate/data/apps.json`.

Alternatively the config can be passed directly as env with:

- APPS_CONFIG_JSON

The config looks like this:

```json
 {
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

### Reloading

Sending a SIGHUP to the container will rebuild the template and reload openresty.

### JSON Spec

**An app can have multiple subdomains**

Top level options

    |Service options      |Required|Default|Description                                      |
    |----------------------------------------------------------------------------------------|
    |`workerConnections`  |false   |   1024|No of worker connections                         |
    |`proxyReadTimeout`   |false   |    120|Read timeout to upstream                         |
    |`proxySendTimeout`   |false   |    120|Send timeout to upstream                         |
    |`sendTimeout`        |false   |    120|Send timeout                                     |
    |`readTimeout`        |false   |    120|Read timeout                                     |
    |`authRequestRedirect`|false   |       |Where to redirect to if auth request fails       |
    |`authRequestUpstream`|false   |       |Where to send auth requests to                   |
    |`authRequestCookie`  |false   |       |Name of cookie to take bearer token from         |
    |`resolver`           |false   |       |DNS resolver ip                                  |

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
    |--------------------------------------------------------------------------------------|
    |`host`              |true    |       |The host to proxy to                            |
    |`port`              |true    |       |The port to proxy to                            |

If `origin.type = "local"`

    |Local options      |Required|Default|Description                                     |
    |-------------------------------------------------------------------------------------|
    |`root`             |true    |       |The root dir where the files are hosted         |  
    |`errorPages`       |false   |       |Error pages config                              |
    |`pathRules`        |false   |       |Array of pathRules                              |

`pathRules` options explained

    |Path Rules options    |Required|Default|Description                                     |
    |----------------------------------------------------------------------------------------|
    |`type`                |true    |       |One of [ prefix ]                               |
    |`path`                |true    |       |The url path to apply the rule to               |
    |`stripPath`           |false   |       |Strip the `path` value when proxying requests   |
    |`origin`              |true    |       |Origin object                                   |

Example json:

```json
{
  "type": "prefix",
  "path": "/api/",
  "stripPath": true,
  "origin": {
    "type": "remote",
    "host": "nginx-api.web",
    "port": 80
  }
}
```

`errorPages` options explained

This is an object where keys are the http status code.
Each status code key value is an object with one property `file`.

```json
{
  "404": {
    "file": "404.html"
  }
}
```

NOTE: A subdomain of 'www' also will be available at 'foo.bar' or whatever the base-url is set to.

## Examples

### Static Site Which Proxies /api to Upstream

```json
{
  "services": [
    {
      "name": "static",
      "subdomains": [
        {
          "name": "static",
          "enabled": "true",
          "baseUrl": "test.com",
          "enableSsl": false,
          "port": 80
        }
      ],
      "origin": {
        "type": "local",
        "root": "/data/static/html",
        "fallbacks": [
          "/index.html;"
        ],
        "errorPages": {
          "404": {
            "file": "/404.html"
          }
        },
        "pathRules": [
          {
            "type": "prefix",
            "path": "/api/",
            "stripPath": true,
            "origin": {
              "type": "remote",
              "host": "backend.web",
              "port": 80
            }
          }
        ]
      }
    }
  ]
}
```

# SSL Defaults

A default certificate needs to be supplied, even when using letsencrypt.

These must be named `server.crt` and placed in `/usr/local/openresty/nginx/ssl/<baseUrl>/`.

So generate a self-signed one for worst case and mount it in :)

FYI: A `subdomain` with no `port` will default to 443

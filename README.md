# nginx-pagespeed

[![Docker Pulls](https://img.shields.io/docker/pulls/hitko/nginx-pagespeed.svg)](https://hub.docker.com/r/hitko/nginx-pagespeed/)

The official [nginx](https://hub.docker.com/_/nginx) image with PageSpeed, brotli and Lua. nginx is rebuilt from the nginx.org source package, so paths, configuration layout and entrypoint behaviour are the same as in the official image.

Includes:

-   [nginx](https://nginx.org/) (mainline on `master`, stable on the `stable` branch), statically linked against a current [OpenSSL](https://www.openssl.org/)
-   [PageSpeed](https://github.com/We-Amp/mod_pagespeed) as a dynamic module, built from source against the exact nginx version (the maintained continuation of the archived Apache ngx_pagespeed)
-   [ngx_brotli](https://github.com/google/ngx_brotli) with a statically built brotli
-   [ngx_devel_kit](https://github.com/vision5/ngx_devel_kit) and [lua-nginx-module](https://github.com/openresty/lua-nginx-module) with [LuaJIT](https://github.com/openresty/luajit2), [lua-resty-core](https://github.com/openresty/lua-resty-core) and [lua-resty-lrucache](https://github.com/openresty/lua-resty-lrucache)

All versions are pinned at the top of the [Dockerfile](Dockerfile). Builds are available for `linux/amd64` and `linux/arm64`.

* * *

## Usage

#### Get latest image

```bash
docker pull hitko/nginx-pagespeed:latest
```

Image tags follow nginx: odd minor versions (1.31.x) are mainline and tagged `latest`, `mainline`, `x.x.x` and `x.x`; even minor versions (1.30.x) are stable and tagged `stable`, `x.x.x` and `x.x`.

Serve a directory with PageSpeed enabled:

```bash
docker run --rm -p 80:80 \
                -v /path/to/site:/usr/share/nginx/html:ro \
                -v /path/to/default.conf:/etc/nginx/conf.d/default.conf:ro \
                hitko/nginx-pagespeed:latest
```

#### Create a `docker-compose.yml`

`restart: always` ensures that the container is automatically restarted by Docker in cases like a Docker service or host restart or container exit. The PageSpeed cache lives on a volume so it survives restarts.

```yaml
services:
  nginx:
    restart: always
    image: hitko/nginx-pagespeed:latest
    container_name: nginx
    ports:
      - "80:80"
    volumes:
      - /path/to/site:/usr/share/nginx/html:ro
      - /path/to/default.conf:/etc/nginx/conf.d/default.conf:ro
      - pagespeed-cache:/var/cache/ngx_pagespeed

volumes:
  pagespeed-cache:
```

#### Start the container

    docker compose up -d nginx

You're done!

* * *

## Examples

**Enable PageSpeed** in `/etc/nginx/conf.d/default.conf`. Existing `pagespeed` directives from ngx_pagespeed keep working; see the [PageSpeed documentation](https://modpagespeed.com/docs/) for the full list of filters and options.

```nginx
server {
    listen 80;
    root /usr/share/nginx/html;

    pagespeed on;
    pagespeed FileCachePath /var/cache/ngx_pagespeed;
}
```

**Enable brotli compression** alongside gzip:

```nginx
server {
    listen 80;
    root /usr/share/nginx/html;

    brotli on;
    brotli_types text/plain text/css application/javascript application/json image/svg+xml;
    brotli_static on;
}
```

**Run Lua** in a location:

```nginx
server {
    listen 80;

    location /hello {
        default_type text/plain;
        content_by_lua_block {
            ngx.say("hello from ", jit.version)
        }
    }
}
```

**Bring your own `nginx.conf`**. PageSpeed is a dynamic module and nginx only loads those through a `load_module` directive. The image's own `nginx.conf` has it, and on start a hook adds it to a mounted `nginx.conf` that lacks it:

    load_module modules/ngx_pagespeed_module.so;

The hook edits the file in place, so a writable bind-mounted `nginx.conf` is changed on the host as well (once). A read-only mount (`:ro`) is left alone with a warning; add the line yourself in that case.

* * *

## Environment variables

The variables of the [official nginx image](https://hub.docker.com/_/nginx) (templates, `NGINX_ENTRYPOINT_QUIET_LOGS`, ...) work unchanged. In addition:

#### NGINX_PAGESPEED_AUTOLOAD

-   **1** => add `load_module modules/ngx_pagespeed_module.so;` to `/etc/nginx/nginx.conf` on start if it is missing
-   **0** => never touch `nginx.conf`

* * *

## Building

The PageSpeed stage compiles the whole PageSpeed library with Bazel and is slow (tens of minutes) and memory hungry (roughly 1.5 GB per job). Cap it on small machines:

```bash
docker build --build-arg PAGESPEED_JOBS=4 -t nginx-pagespeed .
```

For a multi-arch image:

```bash
docker buildx build --platform linux/amd64,linux/arm64 --build-arg PAGESPEED_JOBS=4 -t nginx-pagespeed --push .
```

Releases are built and published by the [GitHub Actions workflow](.github/workflows/docker.yml) on every `v*` tag: each platform builds on a native runner and the multi-arch manifest is assembled at the end.

# ---------------------------------------------------------------------------
# Stage 1: PageSpeed dynamic module (We-Amp mod_pagespeed), built from source
# against the exact nginx version with We-Amp's own per-distro recipe.
# ---------------------------------------------------------------------------
FROM nginx:1.31.8 AS pagespeed

ENV NGINX_VERSION=1.31.8
ENV MPS_VERSION=2.5.2
ENV CODENAME=trixie

RUN apt-get update && apt-get install -y wget

WORKDIR /pagespeed

RUN wget -O mod_pagespeed.tar.gz https://github.com/We-Amp/mod_pagespeed/releases/download/module-v${MPS_VERSION}/mod_pagespeed-${MPS_VERSION}.tar.gz \
    && tar -xzf mod_pagespeed.tar.gz \
    && rm mod_pagespeed.tar.gz
RUN wget -O nginx.tar.gz "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"

RUN cd mod_pagespeed-${MPS_VERSION} \
    && NGINX_SRC_VERSION=${NGINX_VERSION} NGINX_SRC_SHA256=$(sha256sum ../nginx.tar.gz | awk '{print ""$1""}') \
    install/nginx/build_module_in_container.sh ${CODENAME} -o /pagespeed/ngx_pagespeed_module.so

# ---------------------------------------------------------------------------
# Stage 2: nginx .deb rebuilt from the nginx.org source package with
# brotli, ngx_devel_kit and lua-nginx-module compiled in.
# ---------------------------------------------------------------------------
FROM nginx:1.31.8 AS nginx

ENV NGINX_VERSION=1.31.8
ENV OSSL_VERSION=4.0.3
ENV BROTLI_VERSION=1.2.1
ENV NDK_VERSION=0.3.4
ENV NGINX_LUA_VERSION=0.10.32rc7
ENV LUA_JIT_VERSION=2.1-20261023
ENV LUA_VERSION=5.1
ENV LUA_RESTY_VERSION=0.1.35rc2
ENV LUA_RESTY_LRU_VERSION=0.15
ENV CODENAME=trixie

RUN apt-get update \
    && apt-get install -y build-essential zlib1g-dev unzip wget cmake patch

RUN wget -O /etc/apt/keyrings/nginx-archive-keyring.asc https://nginx.org/keys/nginx_signing.key \
    && echo "deb [signed-by=/etc/apt/keyrings/nginx-archive-keyring.asc] https://nginx.org/packages/mainline/debian/ ${CODENAME} nginx" >> /etc/apt/sources.list \
    && echo "deb-src [signed-by=/etc/apt/keyrings/nginx-archive-keyring.asc] https://nginx.org/packages/mainline/debian/ ${CODENAME} nginx" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get build-dep -y nginx=${NGINX_VERSION}-1

WORKDIR /nginx

ADD ./build.sh build.sh

RUN chmod a+x ./build.sh && ./build.sh

# ---------------------------------------------------------------------------
# Stage 3: final image
# ---------------------------------------------------------------------------
FROM nginx:1.31.8
COPY --from=nginx /nginx/nginx_1.31.8-1~trixie_*.deb /_pkgs/
COPY --from=nginx /_lua/deps/usr/local /usr/local
COPY --from=pagespeed /pagespeed/ngx_pagespeed_module.so /usr/lib/nginx/modules/
COPY --chmod=755 docker-entrypoint.d/05-load-pagespeed-module.sh /docker-entrypoint.d/
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/* \
    && dpkg --install /_pkgs/*.deb && rm -rf /_pkgs && ldconfig \
    && sed -i '1i load_module modules/ngx_pagespeed_module.so;' /etc/nginx/nginx.conf

FROM nginx:1.21.0

ENV NGINX_VERSION 1.21.0
ENV NPS_VERSION 1.14.33.1-RC1
ENV OSSL_VERSION 1.1.1k
ENV NDK_VERSION 0.3.1
ENV NGINX_LUA_VERSION 0.10.19
ENV LUA_JIT_VERSION 2.1-20210510
ENV LUA_VERSION 5.1
ENV LUA_RESTY_VERSION 0.1.21
ENV LUA_RESTY_LRU_VERSION 0.10
ENV CODENAME buster

RUN apt-get update \
    && apt-get install -y build-essential zlib1g-dev libpcre3 libpcre3-dev unzip wget libcurl4-openssl-dev libjansson-dev uuid-dev libbrotli-dev

RUN wget http://nginx.org/keys/nginx_signing.key \
    && apt-key add nginx_signing.key \
    && echo "deb http://nginx.org/packages/mainline/debian/ ${CODENAME} nginx" >> /etc/apt/sources.list \
    && echo "deb-src http://nginx.org/packages/mainline/debian/ ${CODENAME} nginx" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get build-dep -y nginx=${NGINX_VERSION}-1

WORKDIR /nginx

ADD ./build.sh build.sh

RUN chmod a+x ./build.sh && ./build.sh
RUN apt-get download libbrotli1



FROM nginx:1.21.0
COPY --from=0 /nginx/nginx_1.21.0-1~buster_amd64.deb /nginx/libbrotli1*.deb /_pkgs/
COPY --from=0 /_lua/deps/usr/local /usr/local
RUN dpkg --install /_pkgs/*.deb && rm -rf /_pkgs

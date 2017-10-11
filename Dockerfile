FROM nginx:1.13.5

ENV NGINX_VERSION 1.13.5
ENV NPS_VERSION 1.12.34.3
ENV OSSL_VERSION 1.1.0f
ENV CODENAME stretch

RUN apt-get update \
    && apt-get install -y build-essential zlib1g-dev libpcre3 libpcre3-dev unzip wget libcurl4-openssl-dev libjansson-dev

RUN wget http://nginx.org/keys/nginx_signing.key \
    && apt-key add nginx_signing.key \
    && echo "deb http://nginx.org/packages/mainline/debian/ ${CODENAME} nginx" >> /etc/apt/sources.list \
    && echo "deb-src http://nginx.org/packages/mainline/debian/ ${CODENAME} nginx" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get build-dep -y nginx=${NGINX_VERSION}

WORKDIR /nginx

ADD ./build.sh build.sh

RUN ./build.sh



FROM nginx:1.13.5
COPY --from=0 /nginx/nginx_1.13.5-2~stretch_amd64.deb /nginx-pagespeed.deb
RUN dpkg --install /nginx-pagespeed.deb && rm /nginx-pagespeed.deb
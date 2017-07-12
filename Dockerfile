FROM nginx:1.13.2

RUN apt-get update \
    && apt-get install -y libcurl3 libjansson4

ADD ./nginx_1.13.2-1~stretch_amd64.deb /nginx-pagespeed.deb

RUN dpkg --install /nginx-pagespeed.deb
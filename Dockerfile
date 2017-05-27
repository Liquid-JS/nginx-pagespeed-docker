FROM nginx:1.13.0

ADD ./nginx_1.13.0-1~stretch_amd64.deb /nginx-pagespeed.deb

RUN dpkg --install /nginx-pagespeed.deb
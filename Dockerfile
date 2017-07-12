FROM nginx:1.13.3

ADD ./nginx_1.13.3-1~stretch_amd64.deb /nginx-pagespeed.deb

RUN dpkg --install /nginx-pagespeed.deb
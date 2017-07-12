FROM nginx:1.13.1

ADD ./nginx_1.13.1-1~stretch_amd64.deb /nginx-pagespeed.deb

RUN dpkg --install /nginx-pagespeed.deb
#!/bin/bash
mkdir -p /nginx
cd /nginx
apt-get source nginx=${NGINX_VERSION}-1
mkdir -p nginx-${NGINX_VERSION}/debian/modules
cd nginx-${NGINX_VERSION}/debian/modules

wget https://github.com/apache/incubator-pagespeed-ngx/archive/refs/heads/master.zip -O release-${NPS_VERSION}.zip
unzip release-${NPS_VERSION}.zip
mv incubator-pagespeed-ngx-master incubator-pagespeed-ngx-${NPS_VERSION}
cd incubator-pagespeed-ngx-${NPS_VERSION}/
#psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz
#[ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
#psol_url=https://archive.apache.org/dist/incubator/pagespeed/1.14.36.1/x64/psol-1.14.36.1-apache-incubating-x64.tar.gz
psol_url=http://www.tiredofit.nl/psol-jammy.tar.xz
wget ${psol_url}
tar -xvf $(basename ${psol_url})

cd /nginx/nginx-${NGINX_VERSION}
wget https://www.openssl.org/source/openssl-${OSSL_VERSION}.tar.gz
tar -xf openssl-${OSSL_VERSION}.tar.gz

cd /nginx/nginx-${NGINX_VERSION}
wget -O brotli.tar.gz https://github.com/google/ngx_brotli/archive/master.tar.gz
tar -xf brotli.tar.gz

cd /nginx/nginx-${NGINX_VERSION}
wget -O ndk.tar.gz https://github.com/vision5/ngx_devel_kit/archive/v${NDK_VERSION}.tar.gz
tar -xf ndk.tar.gz

cd /nginx/nginx-${NGINX_VERSION}
wget -O nginx-lua.tar.gz https://github.com/openresty/lua-nginx-module/archive/v${NGINX_LUA_VERSION}.tar.gz
tar -xf nginx-lua.tar.gz
#mv lua-nginx-module-* lua-nginx-module-${NGINX_LUA_VERSION}

mkdir -p /_lua/deps

cd /nginx/nginx-${NGINX_VERSION}
wget -O lua.tar.gz https://github.com/openresty/luajit2/archive/v${LUA_JIT_VERSION}.tar.gz
tar -xf lua.tar.gz
cd luajit2-${LUA_JIT_VERSION}
make && make install && make DESTDIR=/_lua/deps install

cd /nginx/nginx-${NGINX_VERSION}
wget -O lua-resty.tar.gz https://github.com/openresty/lua-resty-core/archive/v${LUA_RESTY_VERSION}.tar.gz
tar -xf lua-resty.tar.gz
cd lua-resty-core-${LUA_RESTY_VERSION}
sed -i "s/#LUA_VERSION/LUA_VERSION/" Makefile
sed -i "s/lib\/lua/share\/lua/" Makefile
make && make DESTDIR=/_lua/deps install

cd /nginx/nginx-${NGINX_VERSION}
wget -O lua-resty-lru.tar.gz https://github.com/openresty/lua-resty-lrucache/archive/v${LUA_RESTY_LRU_VERSION}.tar.gz
tar -xf lua-resty-lru.tar.gz
cd lua-resty-lrucache-${LUA_RESTY_LRU_VERSION}
sed -i "/PREFIX ?=/i LUA_VERSION := 5.1" Makefile
sed -i "s/lib\/lua/share\/lua/" Makefile
make && make DESTDIR=/_lua/deps install

export LUAJIT_LIB=/usr/local/lib
export LUAJIT_INC=/usr/local/include/luajit-2.1

cd /nginx/nginx-${NGINX_VERSION}
sed -i "0,/CFLAGS\=\\\"\\\"/{/CFLAGS\=\\\"\\\"/ s/$/ --with-ld-opt=-lpcre --add-module=\/nginx\/nginx-${NGINX_VERSION}\/debian\/modules\/incubator-pagespeed-ngx-${NPS_VERSION} ${PS_NGX_EXTRA_FLAGS} --add-module=\/nginx\/nginx-${NGINX_VERSION}\/ngx_brotli-master --add-module=\/nginx\/nginx-${NGINX_VERSION}\/ngx_devel_kit-${NDK_VERSION} --add-module=\/nginx\/nginx-${NGINX_VERSION}\/lua-nginx-module-${NGINX_LUA_VERSION}/}" /nginx/nginx-${NGINX_VERSION}/debian/rules
sed -i "s/CFLAGS\=\\\"\\\"/CFLAGS\=\\\"-Wno-missing-field-initializers\\\"/" /nginx/nginx-${NGINX_VERSION}/debian/rules
sed -i "s/dh_shlibdeps -a/dh_shlibdeps -a --dpkg-shlibdeps-params=--ignore-missing-info/" /nginx/nginx-${NGINX_VERSION}/debian/rules
#sed "41 a --add-module=/nginx/nginx-${NGINX_VERSION}/debian/modules/ngx_pagespeed-release-${NPS_VERSION} ${PS_NGX_EXTRA_FLAGS}" -i /nginx/nginx-${NGINX_VERSION}/debian/rules
#sed "46 a --with-openssl=/nginx/nginx-${NGINX_VERSION}/openssl-${OSSL_VERSION}" -i /nginx/nginx-${NGINX_VERSION}/debian/rules

dpkg-buildpackage -b

#mkdir -p /nginx-dist
#cp /nginx/*.deb /nginx-dist/

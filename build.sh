#!/bin/bash
set -e
mkdir -p /nginx
cd /nginx
apt-get source nginx=${NGINX_VERSION}-1
cd /nginx/nginx-${NGINX_VERSION}
wget -O openssl.tar.gz https://github.com/openssl/openssl/releases/download/openssl-${OSSL_VERSION}/openssl-${OSSL_VERSION}.tar.gz
tar -xzf openssl.tar.gz

cd /nginx/nginx-${NGINX_VERSION}
wget -O brotli.tar.gz https://github.com/google/ngx_brotli/archive/master.tar.gz
tar -xf brotli.tar.gz
# ngx_brotli links against a static brotli built in deps/brotli/out (git submodule); vendor the pinned release instead
wget -O brotli-lib.tar.gz https://github.com/google/brotli/archive/v${BROTLI_VERSION}.tar.gz
tar -xf brotli-lib.tar.gz
rm -rf ngx_brotli-master/deps/brotli && mv brotli-${BROTLI_VERSION} ngx_brotli-master/deps/brotli
mkdir -p ngx_brotli-master/deps/brotli/out && cd ngx_brotli-master/deps/brotli/out
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON .. && cmake --build . --config Release --target brotlienc

cd /nginx/nginx-${NGINX_VERSION}
wget -O ndk.tar.gz https://github.com/vision5/ngx_devel_kit/archive/v${NDK_VERSION}.tar.gz
tar -xf ndk.tar.gz
# nginx 1.31.3+/1.30.4+ changed the script engine; apply the fix nginx's own packaging (pkg-oss) carries for NDK
wget -O ndk-complex-value.patch https://raw.githubusercontent.com/nginx/pkg-oss/${NGINX_VERSION}-1/contrib/src/ngx_devel_kit/0001-fix-complex-value-end-code-for-nginx-1.31.3.patch
patch -p1 -d ngx_devel_kit-${NDK_VERSION} < ndk-complex-value.patch

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
sed -i "0,/CFLAGS\=\\\"\\\"/{/CFLAGS\=\\\"\\\"/ s/$/ --with-openssl=\/nginx\/nginx-${NGINX_VERSION}\/openssl-${OSSL_VERSION} --with-openssl-opt=\"no-tests no-module\" --add-module=\/nginx\/nginx-${NGINX_VERSION}\/ngx_brotli-master --add-module=\/nginx\/nginx-${NGINX_VERSION}\/ngx_devel_kit-${NDK_VERSION} --add-module=\/nginx\/nginx-${NGINX_VERSION}\/lua-nginx-module-${NGINX_LUA_VERSION}/}" /nginx/nginx-${NGINX_VERSION}/debian/rules
sed -i "s/CFLAGS\=\\\"\\\"/CFLAGS\=\\\"-Wno-missing-field-initializers\\\"/" /nginx/nginx-${NGINX_VERSION}/debian/rules
sed -i "s/dh_shlibdeps -a/dh_shlibdeps -a --dpkg-shlibdeps-params=--ignore-missing-info/" /nginx/nginx-${NGINX_VERSION}/debian/rules

dpkg-buildpackage -b

#mkdir -p /nginx-dist
#cp /nginx/*.deb /nginx-dist/

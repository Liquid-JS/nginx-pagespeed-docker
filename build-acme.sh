#!/bin/bash
mkdir -p /nginx
cd /nginx
apt-get source nginx=${NGINX_VERSION}
mkdir -p nginx-${NGINX_VERSION}/debian/modules
cd nginx-${NGINX_VERSION}/debian/modules

wget https://github.com/pagespeed/ngx_pagespeed/archive/v${NPS_VERSION}-beta.zip -O release-${NPS_VERSION}-beta.zip
unzip release-${NPS_VERSION}-beta.zip
cd ngx_pagespeed-${NPS_VERSION}-beta/
psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz
[ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
wget ${psol_url}
tar -xzvf $(basename ${psol_url})

cd /nginx/nginx-${NGINX_VERSION}/debian/modules
wget https://github.com/Liquid-JS/ngx_http_acme_module/archive/master.zip
unzip master.zip

cd /nginx/nginx-${NGINX_VERSION}
wget https://www.openssl.org/source/openssl-${OSSL_VERSION}.tar.gz
tar -xf openssl-${OSSL_VERSION}.tar.gz
sed -i "0,/CFLAGS\=\\\"\\\"/{/CFLAGS\=\\\"\\\"/ s/$/ --add-module=\/nginx\/nginx-${NGINX_VERSION}\/debian\/modules\/ngx_pagespeed-${NPS_VERSION}-beta --add-module=\/nginx\/nginx-${NGINX_VERSION}\/debian\/modules\/ngx_http_acme_module-master ${PS_NGX_EXTRA_FLAGS} --with-openssl=\/nginx\/nginx-${NGINX_VERSION}\/openssl-${OSSL_VERSION}/}" /nginx/nginx-${NGINX_VERSION}/debian/rules
#sed "41 a --add-module=/nginx/nginx-${NGINX_VERSION}/debian/modules/ngx_pagespeed-release-${NPS_VERSION}-beta ${PS_NGX_EXTRA_FLAGS}" -i /nginx/nginx-${NGINX_VERSION}/debian/rules
#sed "46 a --with-openssl=/nginx/nginx-${NGINX_VERSION}/openssl-${OSSL_VERSION}" -i /nginx/nginx-${NGINX_VERSION}/debian/rules

dpkg-buildpackage -b

mkdir -p /nginx-dist
cp /nginx/*.deb /nginx-dist/
FROM alpine:latest

MAINTAINER from coeus03013038@gmail.com by simon

ENV TERM=linux

RUN apk update && apk add bash curl ca-certificates openssl curl tar iproute2 && rm -rf /var/cache/apk/*

ARG VERSION=1.10.2

ARG AUTOINDEX_NAME_LEN=100

ENV INSTALL_DIR=/usr/local/nginx DATA_DIR=/data/wwwroot TEMP_DIR=/tmp/nginx

RUN  mkdir -p $(dirname ${DATA_DIR}) ${TEMP_DIR} && cd ${TEMP_DIR} && \
DOWN_URL="http://nginx.org/download" && \
DOWN_URL="${DOWN_URL}/nginx-${VERSION}.tar.gz" && \
FILE_NAME=${DOWN_URL##*/} && \
mkdir -p ${TEMP_DIR}/${FILE_NAME%%\.tar*} && \
apk --update --no-cache upgrade && \
apk add --no-cache --virtual .build-deps geoip geoip-dev pcre libxslt gd openssl-dev pcre-dev zlib-dev build-base linux-headers libxslt-dev gd-dev openssl-dev libstdc++ libgcc patch git tar curl && \
curl -Lk ${DOWN_URL} | tar xz -C ${TEMP_DIR} --strip-components=1 && \
git clone https://github.com/arut/nginx-rtmp-module.git -b v1.1.7 && \
git clone https://github.com/xiaokai-wang/nginx_upstream_check_module.git && \
git clone https://github.com/xiaokai-wang/nginx-stream-upsync-module.git && \
addgroup -g 400 -S www && \
adduser -u 400 -S -h ${DATA_DIR} -s /sbin/nologin -g 'WEB Server' -G www www && \
find ${TEMP_DIR} -type f -exec sed -i 's/\r$//g' {} \; && \
sed -ri "s/^(#define NGX_HTTP_AUTOINDEX_NAME_LEN).*/\1  ${AUTOINDEX_NAME_LEN}/" src/http/modules/ngx_http_autoindex_module.c && \
sed -ri "s/^(#define NGX_HTTP_AUTOINDEX_PREALLOCATE).*/\1  ${AUTOINDEX_NAME_LEN}/" src/http/modules/ngx_http_autoindex_module.c && \
patch -p0 < ./nginx_upstream_check_module/check_1.9.2+.patch && \
CFLAGS=-Wno-unused-but-set-variable ./configure --prefix=${INSTALL_DIR} \
							     --user=www \
							     --group=www \
							     --error-log-path=/data/wwwlogs/error.log \
							     --http-log-path=/data/wwwlogs/access.log \
							     --pid-path=/var/run/nginx/nginx.pid \
							     --lock-path=/var/lock/nginx.lock \
							     --with-pcre \
							     --with-ipv6 \
							     --with-mail \
							     --with-mail_ssl_module \
							     --with-pcre-jit \
							     --with-file-aio \
							     --with-threads \
							     --with-stream \
							     --with-stream_ssl_module \
							     --with-http_ssl_module \
							     --with-http_flv_module \
							     --with-http_v2_module \
							     --with-http_realip_module \
							     --with-http_gzip_static_module \
							     --with-http_stub_status_module \
							     --with-http_sub_module \
							     --with-http_mp4_module \
							     --with-http_image_filter_module \
							     --with-http_addition_module \
							     --with-http_auth_request_module \
							     --with-http_dav_module \
							     --with-http_degradation_module \
							     --with-http_geoip_module \
							     --with-http_xslt_module \
							     --with-http_gunzip_module \
							     --with-http_secure_link_module \
							     --with-http_slice_module \
							     --http-client-body-temp-path=${INSTALL_DIR}/client/ \
							     --http-proxy-temp-path=${INSTALL_DIR}/proxy/ \
							     --http-fastcgi-temp-path=${INSTALL_DIR}/fcgi/ \
							     --http-uwsgi-temp-path=${INSTALL_DIR}/uwsgi \
							     --http-scgi-temp-path=${INSTALL_DIR}/scgi &&\
					make  && \
					make install && \
runDeps="$( scanelf --needed --nobanner --recursive /usr/local | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' | sort -u | xargs -r apk info --installed | sort -u )" && \
runDeps="${runDeps} inotify-tools supervisor logrotate python" && \
apk add --no-cache --virtual .ngx-rundeps $runDeps && 	apk del .build-deps && \
rm -rf /var/cache/apk/* /tmp/* ${INSTALL_DIR}/conf/nginx.conf

ENV PATH=/usr/local/nginx/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TERM=linux

#ADD 

ADD entrypoint.sh /entrypoint.sh

VOLUME [/data/wwwroot]

EXPOSE 443/tcp 80/tcp

ENTRYPOINT ["/entrypoint.sh"] 

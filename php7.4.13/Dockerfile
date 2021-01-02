FROM alpine:3.12

MAINTAINER from www.github.com/coeus-lei by simon

ENV  VERSION=${VERSION:-7.4.13} \
     SHA256=${SHA256:-0865cff41e7210de2537bcd5750377cfe09a9312b9b44c1a166cf372d5204b8f} \
     SWOOLE_VERSION=${SWOOLE_VERSION:-4.4.3} \
     INSTALL_DIR=/usr/local/php \
       TEMP_DIR=/tmp/php
	
RUN set -x && \
#Change Mirrors
        PHP_URL="https://secure.php.net/get/php-${VERSION}.tar.xz/from/this/mirror" && \
        MEMCACHE_DEPS="libmemcached-dev cyrus-sasl-dev libsasl linux-headers git" && \
	PHP_LDFLAGS="-Wl,-O1 -pie" && \
	PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64" && \
	PHP_CPPFLAGS="$PHP_CFLAGS" && \
	PHPIZE_DEPS="autoconf dpkg-dev dpkg file g++ gcc libc-dev make pkgconf re2c gettext-dev imap-dev oniguruma-dev icu-dev" && \
#Mkdri TEMP_DIR
        mkdir -p ${TEMP_DIR} /tmp/memcache && cd /tmp && \
#Upgrade OS and install
        apk --update --no-cache upgrade && \
	apk add --no-cache --virtual .build-deps $PHPIZE_DEPS ca-certificates ${MEMCACHE_DEPS} \
	curl tar xz openssl gnupg argon2-dev coreutils curl-dev libpng-dev php7-memcache \
	libedit-dev libxslt-dev libzip libzip-dev libsodium-dev libxml2-dev linux-headers oniguruma-dev openssl-dev sqlite-dev && \
	export CFLAGS="$PHP_CFLAGS" \
	CPPFLAGS="$PHP_CPPFLAGS" \
	LDFLAGS="$PHP_LDFLAGS" && \
#Add run php user&group
	addgroup -g 400 -S www && \
	adduser -u 400 -S -H -s /sbin/nologin -g 'PHP' -G www www && \
#Download File
        curl -Lk "${PHP_URL}" | tar xJ -C ${TEMP_DIR} --strip-components=1 && \
#Install PHP
        cd ${TEMP_DIR}/ && \
        PHP_EXTRA_CONFIGURE_ARGS="--enable-fpm --with-fpm-user=www --with-fpm-group=www --disable-cgi" && \
        gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" && \
	./configure --prefix=${INSTALL_DIR} \
          --build="$gnuArch" \
          --with-config-file-path="${INSTALL_DIR}/etc" \
          --with-config-file-scan-dir="${INSTALL_DIR}/etc/php.d" \
          --enable-option-checking=fatal \
          --with-mhash \
          --with-pic \
          --enable-ftp \
          --enable-mbstring \
	  --with-mysqli=mysqlnd \
          --enable-mysqlnd \
          --with-password-argon2 \
          --with-sodium=shared \
          --with-pdo-sqlite=/usr \
          --with-sqlite3=/usr \
          --with-curl \
          --with-libedit \
          --with-openssl \
	  --enable-bcmath \
	  --enable-sysvsem \
	  --with-xmlrpc \
	  --with-zip \
	  --with-xsl \
          --with-zlib \
          --enable-opcache \
          --enable-sockets \
          --enable-soap \
          --enable-shmop \
          --enable-pcntl \
          --enable-intl \
          --disable-ipv6 \
          --enable-gd \
          --with-gettext \
          --enable-exif \
          --with-imap \
          --with-imap-ssl \
          -with-openssl \
          --with-pear \
          $(test "$gnuArch" = 's390x-linux-musl' && echo '--without-pcre-jit') \
          ${PHP_EXTRA_CONFIGURE_ARGS:-} && \
	make -j "$(nproc)" && \
	find -type f -name '*.a' -delete && \
	make install && \
	[ ! -e "${INSTALL_DIR}/etc/php.d" ] && mkdir -p ${INSTALL_DIR}/etc/php.d && \
	/bin/cp php.ini-production ${INSTALL_DIR}/etc/php.ini && \
	apk add --no-cache php7-memcache libmemcached-dev imagemagick-dev && \
	#mv /usr/lib/php7/modules/memcache.so ${INSTALL_DIR}/lib/php/extensions/no-debug-non-zts-20190902/memcache.so && \
	find /usr/local/bin /usr/local/sbin -type f -perm +0111 -exec strip --strip-all '{}' + || true && \
	make clean && \
	cd / && \
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)" && \
	${INSTALL_DIR}/bin/pecl update-channels && \
	${INSTALL_DIR}/bin/pecl install http://pecl.php.net/get/memcache-4.0.5.2.tgz && \
	${INSTALL_DIR}/bin/pecl install http://pecl.php.net/get/mongodb-1.9.0.tgz && \
        ${INSTALL_DIR}/bin/pecl install http://pecl.php.net/get/memcached-3.1.3.tgz && \
        ${INSTALL_DIR}/bin/pecl install https://pecl.php.net/get/redis-5.0.2.tgz && \
        ${INSTALL_DIR}/bin/pecl install https://pecl.php.net/get/imagick-3.4.4.tgz && \
        curl -Lk "http://pecl.php.net/get/swoole-${SWOOLE_VERSION}.tgz" | tar xz -C /tmp && \
        cd /tmp/swoole-${SWOOLE_VERSION} && \
	${INSTALL_DIR}/bin/phpize && \
	./configure --with-php-config=${INSTALL_DIR}/bin/php-config && \
	make -j "$(nproc)" && \
	make install && \
	apk add --no-cache --virtual .php-rundeps $runDeps && \
	apk del .build-deps && \
	rm -rf /tmp/pear ~/.pearrc /var/cache/apk/* /tmp/*

ENV PATH=${INSTALL_DIR}/bin:$PATH
ENV PATH=${INSTALL_DIR}/sbin:$PATH \
        TERM=linux

COPY entrypoint.sh /entrypoint.sh
ADD php-fpm.conf ${INSTALL_DIR}/etc/php-fpm.conf

ENTRYPOINT ["/entrypoint.sh"]

CMD ["php-fpm"]

FROM php:7.1-fpm-jessie

LABEL maintainer="Nimrod Nagy <nimrod.nagy@lynxsolutions.eu>"

ENV php_conf /usr/local/etc/php-fpm.conf
ENV fpm_conf /usr/local/etc/php-fpm.d/www.conf
ENV php_vars /usr/local/etc/php/conf.d/docker-vars.ini

ENV NGINX_VERSION 1.15.5-1~jessie
ENV GPG_KEYS B0F4253373F8F6F510D42178520A9993A1C052F8
ENV SERVER hkp://keyserver.ubuntu.com:80

RUN apt-get update  \
	&& apt-get install --no-install-recommends --force-yes --no-install-suggests -y \
  supervisor \
  wget \
	gnupg2 \
	dirmngr \
	autoconf \
	pkg-config \
	libssl-dev

ENV PHP_AUTOCONF /usr/bin/autoconf

RUN apt-key adv --keyserver ${SERVER} --keyserver-options timeout=10 --recv-keys ${GPG_KEYS} \
	&& echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list \
	&& apt-get update \
	&& apt-get install --no-install-recommends --force-yes --no-install-suggests -y \
						ca-certificates \
						nginx=${NGINX_VERSION} \
						nginx-module-xslt=${NGINX_VERSION} \
						nginx-module-geoip=${NGINX_VERSION} \
						nginx-module-image-filter=${NGINX_VERSION} \
						nginx-module-perl=${NGINX_VERSION} \
#						nginx-module-njs=${NGINX_VERSION} \
						gettext-base \
	&& rm -rf /var/lib/apt/lists/*

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

RUN pecl install mongodb-1.4.0
RUN echo "extension=mongodb.so" >> /usr/local/etc/php/conf.d/mongodb.ini

RUN apt-get update \
	&& apt-get install --no-install-recommends --force-yes --no-install-suggests -y \
	openssh-client \
    wget \
    supervisor \
    git \
    python \
    python-dev \
    python-pip \
    ca-certificates \
    dialog \
    make \
    gcc \
    musl-dev \
    libssl-dev \
    libffi-dev \
    libfreetype6-dev \
    libsqlite3-dev \
    libmcrypt-dev \
    libicu-dev \
    libxslt-dev \
    libxrender1 \
    libxext6 \
    libjpeg62-turbo-dev \
    libmagickcore-dev \
    libmagickwand-dev && \
    docker-php-ext-configure gd \
      --with-gd \
      --with-freetype-dir=/usr/include/ \
      --with-png-dir=/usr/include/ \
      --with-jpeg-dir=/usr/include/ && \
    yes '' | pecl install imagick-3.4.3 && \
    docker-php-ext-enable imagick && \
    #curl iconv session
    docker-php-ext-install pdo_mysql pdo_sqlite mysqli mcrypt gd exif intl xsl json soap dom zip opcache bcmath mbstring && \
    pecl install xdebug && \
    docker-php-source delete && \
    mkdir -p /etc/nginx && \
    mkdir -p /var/www/app && \
    mkdir -p /run/nginx && \
    mkdir -p /var/log/supervisor && \
    EXPECTED_COMPOSER_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig) && \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php -r "if (hash_file('SHA384', 'composer-setup.php') === '${EXPECTED_COMPOSER_SIGNATURE}') { echo 'Composer.phar Installer verified'; } else { echo 'Composer.phar Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php --install-dir=/usr/bin --filename=composer && \
    php -r "unlink('composer-setup.php');" && \
    pip install -U setuptools && \
    pip install -U pip && \
    apt-get remove gcc musl-dev libffi-dev python-dev make autoconf -y
#    ln -s /usr/bin/php7 /usr/bin/php



ADD conf/supervisord.conf /etc/supervisord.conf

# Copy our nginx config
RUN rm -rf /etc/nginx/nginx.conf
ADD conf/nginx.conf /etc/nginx/nginx.conf

# nginx site conf
RUN mkdir -p /etc/nginx/sites-available/ && \
mkdir -p /etc/nginx/sites-enabled/ && \
rm -Rf /var/www/* && \
mkdir /var/www/html/

ADD conf/nginx-site.conf /etc/nginx/sites-available/default.conf
RUN ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf

# tweak php-fpm config
RUN echo "cgi.fix_pathinfo=0" > ${php_vars} &&\
    echo "upload_max_filesize = 100M"  >> ${php_vars} &&\
    echo "post_max_size = 100M"  >> ${php_vars} &&\
    echo "variables_order = \"EGPCS\""  >> ${php_vars} && \
    echo "memory_limit = 512M"  >> ${php_vars} && \
    sed -i \
        -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" \
        -e "s/pm.max_children = 5/pm.max_children = 4/g" \
        -e "s/pm.start_servers = 2/pm.start_servers = 3/g" \
        -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" \
        -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" \
        -e "s/;pm.max_requests = 500/pm.max_requests = 200/g" \
        -e "s/user = www-data/user = nginx/g" \
        -e "s/group = www-data/group = nginx/g" \
        -e "s/;listen.mode = 0660/listen.mode = 0666/g" \
        -e "s/;listen.owner = www-data/listen.owner = nginx/g" \
        -e "s/;listen.group = www-data/listen.group = nginx/g" \
        -e "s/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g" \
        -e "s/^;clear_env = no$/clear_env = no/" \
        ${fpm_conf}
#    ln -s /etc/php7/php.ini /etc/php7/conf.d/php.ini && \
#    find /etc/php7/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;


EXPOSE 80

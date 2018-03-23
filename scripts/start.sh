#!/bin/bash

# Prevent config files from being filled to infinity by force of stop and restart the container
lastlinephpconf="$(grep "." /usr/local/etc/php-fpm.conf | tail -1)"
if [[ $lastlinephpconf == *"php_flag[display_errors]"* ]]; then
 sed -i '$ d' /usr/local/etc/php-fpm.conf
fi


#echo php_flag[display_errors] = off >> /usr/local/etc/php-fpm.conf
echo php_flag[display_errors] = on >> /usr/local/etc/php-fpm.conf

# Display Version Details or not
 #sed -i "s/server_tokens off;/server_tokens on;/g" /etc/nginx/nginx.conf
 sed -i "s/expose_php = On/expose_php = Off/g" /usr/local/etc/php-fpm.conf

# Pass real-ip to logs when behind ELB, etc
if [[ "$REAL_IP_HEADER" == "1" ]] ; then
 sed -i "s/#real_ip_header X-Forwarded-For;/real_ip_header X-Forwarded-For;/" /etc/nginx/sites-available/default.conf
 sed -i "s/#set_real_ip_from/set_real_ip_from/" /etc/nginx/sites-available/default.conf
 if [ ! -z "$REAL_IP_FROM" ]; then
  sed -i "s#172.16.0.0/12#$REAL_IP_FROM#" /etc/nginx/sites-available/default.conf
 fi
fi

#Display errors in docker logs
echo "log_errors = On" >> /usr/local/etc/php/conf.d/docker-vars.ini
echo "error_log = /dev/stderr" >> /usr/local/etc/php/conf.d/docker-vars.ini

# Increase the memory_limit
#  sed -i "s/memory_limit = 128M/memory_limit = ${PHP_MEM_LIMIT}M/g" /usr/local/etc/php/conf.d/docker-vars.ini

# Increase the post_max_size
#  sed -i "s/post_max_size = 100M/post_max_size = ${PHP_POST_MAX_SIZE}M/g" /usr/local/etc/php/conf.d/docker-vars.ini

# Increase the upload_max_filesize
#  sed -i "s/upload_max_filesize = 100M/upload_max_filesize= ${PHP_UPLOAD_MAX_FILESIZE}M/g" /usr/local/etc/php/conf.d/docker-vars.ini

XdebugFile='/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini'
if [ -f $XdebugFile ]; then
    echo "Disabling Xdebug"
    rm $XdebugFile
fi
# fi

if [ ! -z "$PUID" ]; then
  if [ -z "$PGID" ]; then
    PGID=${PUID}
  fi
  deluser nginx
  addgroup -g ${PGID} nginx
  adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx -u ${PUID} nginx
else
  if [ -z "$SKIP_CHOWN" ]; then
    chown -Rf nginx.nginx /var/www/html
  fi
fi

# Start supervisord and services
exec /usr/bin/supervisord -n -c /etc/supervisord.conf

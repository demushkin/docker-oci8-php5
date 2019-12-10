FROM php:5.6-apache

RUN apt-get update && apt-get install -y \
        unzip \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libaio1 \
    && docker-php-ext-install -j$(nproc) iconv mcrypt gettext \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd

COPY ./docker-php.conf /etc/apache2/conf-enabled/docker-php.conf

RUN printf "log_errors = On \nerror_log = /dev/stderr\n" > /usr/local/etc/php/conf.d/php-logs.ini

RUN a2enmod rewrite

RUN pecl channel-update pecl.php.net

RUN cd /tmp && curl -k -L https://zet.im/oci8/instantclient-basiclite-linux.x64-19.5.0.0.0dbru.zip -O
RUN cd /tmp && curl -k -L https://zet.im/oci8/instantclient-sdk-linux.x64-19.5.0.0.0dbru.zip -O

RUN unzip /tmp/instantclient-basiclite-linux.x64-19.5.0.0.0dbru.zip -d /usr/local/
RUN unzip /tmp/instantclient-sdk-linux.x64-19.5.0.0.0dbru.zip -d /usr/local/


RUN ln -s /usr/local/instantclient_19_5 /usr/local/instantclient
# fixes error "libnnz19.so: cannot open shared object file: No such file or directory"
RUN ln -s /usr/local/instantclient/lib* /usr/lib

RUN echo 'export LD_LIBRARY_PATH="/usr/local/instantclient"' >> /root/.bashrc
RUN echo 'umask 002' >> /root/.bashrc

RUN echo 'instantclient,/usr/local/instantclient' | pecl install oci8-1.4.10
RUN echo "extension=oci8.so" > /usr/local/etc/php/conf.d/php-oci8.ini

EXPOSE 80
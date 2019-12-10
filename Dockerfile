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

RUN apt-get install -y --no-install-recommends libxml2-dev
RUN apt-get install -y libmagickwand-dev libmagickcore-dev libmagickwand-dev libcurl3-dev curl libxslt-dev unzip git
WORKDIR /usr/src/
RUN git clone https://github.com/alexeyrybak/blitz.git
WORKDIR blitz
RUN phpize && ./configure && make && make install
RUN docker-php-ext-enable blitz
WORKDIR /usr/src
RUN rm -rf blitz

RUN docker-php-ext-install xsl intl sockets bcmath pdo pdo_mysql mysqli soap
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

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

RUN apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps

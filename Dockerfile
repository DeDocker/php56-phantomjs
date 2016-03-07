FROM php:5.6-fpm
# Install modules
RUN apt-get update && apt-get install -y \
        libz-dev libmemcached-dev \
        libfreetype6-dev \
#libjpeg62-turbo-dev \
        libjpeg-dev \
        libmcrypt-dev \
        libpng12-dev \
    && docker-php-ext-install iconv mcrypt mbstring zip \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd pdo pdo_mysql mysqli \
    && apt-get install -y libcurl4-openssl-dev \
    && docker-php-ext-install curl

RUN pecl install memcached 
RUN echo 'extension=memcached.so' >> /usr/local/etc/php/conf.d/memcached.ini
RUN pecl install xdebug 
RUN echo 'zend_extension = /usr/local/lib/php/extensions/no-debug-non-zts-20131226/xdebug.so' >> /usr/local/etc/php/php.ini
RUN touch /usr/local/etc/php/conf.d/xdebug.ini; \
    echo xdebug.remote_enable=1 >> /usr/local/etc/php/conf.d/xdebug.ini; \
      echo xdebug.remote_autostart=0 >> /usr/local/etc/php/conf.d/xdebug.ini; \
      echo xdebug.remote_connect_back=1 >> /usr/local/etc/php/conf.d/xdebug.ini; \
      echo xdebug.remote_port=9000 >> /usr/local/etc/php/conf.d/xdebug.ini; \
    echo xdebug.remote_log=/tmp/php5-xdebug.log >> /usr/local/etc/php/conf.d/xdebug.ini;

# Dependencies we just need for building phantomjs
ENV buildDependencies\
  wget unzip python build-essential g++ flex bison gperf\
  ruby perl libsqlite3-dev libssl-dev libpng-dev

# Dependencies we need for running phantomjs
ENV phantomJSDependencies\
  libicu-dev libfontconfig1-dev libjpeg-dev libfreetype6 openssl

# Installing phantomjs
RUN \
    # Installing dependencies
    apt-get update -yqq \
&&  apt-get install -fyqq ${buildDependencies} ${phantomJSDependencies}\
    # Downloading src, unzipping & removing zip
&&  mkdir /phantomjs \
&&  cd /phantomjs \
&&  wget https://github.com/ariya/phantomjs/archive/2.0.0.zip -O phantomjs-2.0.0-source.zip \
&&  unzip phantomjs-2.0.0-source.zip \
&&  rm -rf /phantomjs/phantomjs-2.0.0-source.zip \
    # Building phantom
&&  cd phantomjs-2.0.0/ \
&&  ./build.sh --jobs 1 --confirm --silent \
    # Removing everything but the binary
&&  ls -A | grep -v bin | xargs rm -rf \
    # Symlink phantom so that we are able to run `phantomjs`
&&  ln -s /phantomjs/phantomjs-2.0.0/bin/phantomjs /usr/local/share/phantomjs \
&&  ln -s /phantomjs/phantomjs-2.0.0/bin/phantomjs /usr/local/bin/phantomjs \
&&  ln -s /phantomjs/phantomjs-2.0.0/bin/phantomjs /usr/bin/phantomjs \
    # Removing build dependencies, clean temporary files
&&  apt-get purge -yqq ${buildDependencies} \
&&  apt-get autoremove -yqq \
&&  apt-get clean \
&&  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 

CMD ["php-fpm"]

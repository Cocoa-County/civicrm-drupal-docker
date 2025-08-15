FROM php:8.2-apache

# Install system dependencies and PHP extensions needed by Drupal/CiviCRM
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
     git unzip libpng-dev libjpeg62-turbo-dev libfreetype6-dev \
     libzip-dev libicu-dev libonig-dev libxml2-dev \
     mariadb-client libwebp-dev \
  && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
  && docker-php-ext-install -j"$(nproc)" gd pdo_mysql zip intl opcache \
  && a2enmod rewrite headers expires \
  && rm -rf /var/lib/apt/lists/*

# Set the Apache DocumentRoot to /var/www/html/web
ENV APACHE_DOCUMENT_ROOT=/var/www/html/web
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Dev PHP settings
COPY .docker/web/php.ini /usr/local/etc/php/conf.d/zz-dev.ini

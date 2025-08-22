# Single builder + slim runtime for PHP 8.3 FPM
FROM php:8.3-fpm AS builder
LABEL maintainer="Cocoa-County"

# Build deps (composer + compiling extensions)
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates git unzip zip curl wget libzip-dev zlib1g-dev libicu-dev libxml2-dev \
        libpng-dev libjpeg-dev libwebp-dev libavif-dev libfreetype6-dev libonig-dev locales; \
    rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
WORKDIR /build

# Configure and compile PHP extensions to keep runtime slim
RUN set -eux; \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-avif --with-webp; \
    docker-php-ext-install -j$(nproc) pdo pdo_mysql mysqli bcmath mbstring xml zip intl gd opcache

# Install Drupal, drush, cv, and CiviCRM via Composer
RUN set -eux; \
    composer create-project drupal/recommended-project:"^11" /build/drupal --no-interaction --prefer-dist --no-progress; \
    cd /build/drupal; \
    composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader --no-progress; \
    composer require drush/drush:"*" --no-interaction --prefer-dist --no-progress; \
    wget -qO /usr/local/bin/cv https://download.civicrm.org/cv/cv.phar; chmod +x /usr/local/bin/cv; \
    cd /build/drupal; \
    export COMPOSER_COMPILE=1; \
    composer config extra.enable-patching true; \
    composer config --no-plugins allow-plugins.cweagans/composer-patches true; \
    composer config --no-plugins allow-plugins.civicrm/civicrm-asset-plugin true; \
    composer config --no-plugins allow-plugins.civicrm/composer-downloads-plugin true; \
    composer config --no-plugins allow-plugins.civicrm/composer-compile-plugin true; \
    composer require civicrm/civicrm-core civicrm/civicrm-packages civicrm/civicrm-drupal-8 --no-interaction --prefer-dist --no-progress; \
    composer require civicrm/cli-tools --no-interaction --prefer-dist --no-progress

# Make files dir group-writeable (ownership set when copying to runtime)
RUN mkdir -p /build/drupal/web/sites/default/files && chmod 2775 /build/drupal/web/sites/default/files

FROM php:8.3-fpm AS runtime
LABEL maintainer="Cocoa-County"

# Runtime deps only
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        bash ca-certificates zip unzip libxml2 zlib1g locales curl libicu76 libpng16-16 \
        libjpeg62-turbo libfreetype6 libwebp7 libavif16 libaom3 libheif1 libzip5; \
    rm -rf /var/lib/apt/lists/*

# Copy compiled extensions, php conf, composer, cv and the app
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY --chown=www-data:www-data --from=builder /build/drupal /opt/drupal
COPY --from=builder /usr/local/bin/cv /usr/local/bin/cv

# Link webroot and set PATH
RUN rm -rf /var/www/html || true; ln -sfn /opt/drupal/web /var/www/html
ENV PATH="/opt/drupal/vendor/bin:${PATH}"
WORKDIR /var/www/html

# PHP settings recommended for Drupal
RUN cat > /usr/local/etc/php/conf.d/drupal-recommended.ini <<'INI'
memory_limit=512M
upload_max_filesize=100M
post_max_size=110M
max_execution_time=300
opcache.enable=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
date.timezone=UTC
INI

EXPOSE 9000
COPY docker/drupal-entrypoint.sh /usr/local/bin/drupal-entrypoint.sh
RUN chmod +x /usr/local/bin/drupal-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/drupal-entrypoint.sh"]

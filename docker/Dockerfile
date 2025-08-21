# Multi-stage Dockerfile for PHP 8.3 FPM (builder -> runtime)

###############################################################################
# Drupal Builder: Build and install Drupal
###############################################################################
FROM php:8.3-fpm AS drupal-builder

LABEL maintainer="Cocoa-County"

# Install packages needed for Composer and building extensions
RUN set -eux \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        unzip \
        zip \
        curl \
        # development packages used to compile PHP extensions in the builder
        libzip-dev \
        zlib1g-dev \
        libicu-dev \
        libxml2-dev \
        libpng-dev \
        libjpeg-dev \
        libwebp-dev \
        libavif-dev \
        libfreetype6-dev \
        libonig-dev \
        locales \
    && rm -rf /var/lib/apt/lists/*

# Use official Composer binary
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /build

# Build PHP extensions so the runtime image doesn't need -dev packages
RUN set -eux \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-avif --with-webp \
    && docker-php-ext-install -j$(nproc) \
        pdo \
        pdo_mysql \
        mysqli \
        bcmath \
        mbstring \
        xml \
        zip \
        intl \
        gd \
        opcache

RUN composer create-project drupal/recommended-project:"^11" /build/drupal --no-interaction --prefer-dist --no-progress && \
    cd /build/drupal && composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader --no-progress

RUN cd /build/drupal && composer require drush/drush:"*" --no-interaction --prefer-dist --no-progress

# Ensure sites/default/files is group-writable and setgid. Ownership is set
# later by the runtime COPY --chown instruction.
RUN mkdir -p /build/drupal/web/sites/default/files && \
    chmod 2775 /build/drupal/web/sites/default/files

###############################################################################
# CiviCRM Builder: Build and install CiviCRM
###############################################################################
FROM drupal-builder AS civicrm-builder

LABEL maintainer="Cocoa-County"

#install wget
RUN apt-get update && apt-get install -y --no-install-recommends wget && rm -rf /var/lib/apt/lists/*

# Install cv CLI
RUN wget -qO /usr/local/bin/cv https://download.civicrm.org/cv/cv.phar && chmod +x /usr/local/bin/cv

WORKDIR /build/drupal

# Allow Composer plugins required by CiviCRM packages during automated installs
# ENV COMPOSER_ALLOW_PLUGINS={"cweagans/composer-patches":true,"civicrm/civicrm-asset-plugin":true,"civicrm/composer-downloads-plugin":true,"civicrm/composer-compile-plugin":true}
ENV COMPOSER_COMPILE=1

# SEE: https://docs.civicrm.org/installation/en/latest/drupal/
RUN composer config extra.enable-patching true && \
    composer config --no-plugins allow-plugins.cweagans/composer-patches true && \
    composer config --no-plugins allow-plugins.civicrm/civicrm-asset-plugin true && \
    composer config --no-plugins allow-plugins.civicrm/composer-downloads-plugin true && \
    composer config --no-plugins allow-plugins.civicrm/composer-compile-plugin true && \
    composer require civicrm/civicrm-core civicrm/civicrm-packages civicrm/civicrm-drupal-8 --no-interaction --prefer-dist --no-progress && \
    composer require civicrm/cli-tools --no-interaction --prefer-dist --no-progress

###############################################################################
# Runtime: Create the final runtime image with Drupal and CiviCRM
###############################################################################
FROM php:8.3-fpm AS runtime

LABEL maintainer="Cocoa-County"

# Install runtime packages required by Drupal
RUN set -eux \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    bash \
        ca-certificates \
        zip \
        unzip \
        libxml2 \
        zlib1g \
        locales \
        curl \
        libicu76 \
        libpng16-16 \
        libjpeg62-turbo \
        libfreetype6 \
        libwebp7 \
        libavif16 \
        libaom3 \
        libheif1 \
        libzip5 \
    ; \
    rm -rf /var/lib/apt/lists/*;

# Copy compiled extensions and PHP config from civicrm-builder
COPY --from=civicrm-builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=civicrm-builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# Copy Composer binary (optional)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy built Drupal site to /opt/drupal and set owner to www-data
COPY --chown=www-data:www-data --from=civicrm-builder /build/drupal /opt/drupal

# Replace /var/www/html with a symlink to the Drupal webroot
RUN if [ -d /var/www/html ]; then rm -rf /var/www/html; fi \
    && ln -sfn /opt/drupal/web /var/www/html

# Add project binaries (e.g. vendor/bin/drush) to PATH
ENV PATH="/opt/drupal/vendor/bin:${PATH}"

# Copy cv CLI from builder (downloaded there) into the runtime image
COPY --from=civicrm-builder /usr/local/bin/cv /usr/local/bin/cv

# Work in the Drupal webroot
WORKDIR /var/www/html

# PHP configuration for Drupal
RUN { \
    echo "memory_limit=512M"; \
    echo "upload_max_filesize=100M"; \
    echo "post_max_size=110M"; \
    echo "max_execution_time=300"; \
    echo "opcache.enable=1"; \
    echo "opcache.memory_consumption=128"; \
    echo "opcache.interned_strings_buffer=8"; \
    echo "opcache.max_accelerated_files=4000"; \
    echo "date.timezone=UTC"; \
} > /usr/local/etc/php/conf.d/drupal-recommended.ini

# Expose FPM port
EXPOSE 9000

# Copy and enable the container entrypoint script (runs before php-fpm)
COPY docker/drupal-entrypoint.sh /usr/local/bin/drupal-entrypoint.sh
RUN chmod +x /usr/local/bin/drupal-entrypoint.sh

# Entrypoint will exec php-fpm
ENTRYPOINT ["/usr/local/bin/drupal-entrypoint.sh"]

# Multi-stage Dockerfile for PHP 8.3 FPM (builder -> runtime)

###############################################################################
# Builder: install Composer, build PHP extensions, install project deps
###############################################################################
FROM php:8.3-fpm AS builder

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
RUN chmod 2775 /build/drupal/web/sites/default/files

###############################################################################
# Runtime: PHP-FPM image with runtime deps and built project
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
        zlib1g \
    ; \
    rm -rf /var/lib/apt/lists/*;

# Copy compiled extensions and PHP config from builder
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# Copy Composer binary (optional)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy built Drupal site to /opt/drupal and set owner to www-data
COPY --chown=www-data:www-data --from=builder /build/drupal /opt/drupal

# Replace /var/www/html with a symlink to the Drupal webroot
RUN if [ -d /var/www/html ]; then rm -rf /var/www/html; fi \
    && ln -sfn /opt/drupal/web /var/www/html

# Add project binaries (e.g. vendor/bin/drush) to PATH
ENV PATH="/opt/drupal/vendor/bin:${PATH}"

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

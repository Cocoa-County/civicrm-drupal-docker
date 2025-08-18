### Builder stage
FROM drupal:11.1.8-php8.3-fpm AS builder

# Install build tools and native libraries.
USER root
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        build-essential \
        autoconf \
        pkg-config \
        ca-certificates \
        libxml2-dev \
        libicu-dev \
        libzip-dev \
        libpng-dev \
        libjpeg-dev \
        libfreetype6-dev \
        libwebp-dev \
        libavif-dev \
        libaom-dev \
        libheif-dev \
        zlib1g-dev \
        unzip \
        p7zip-full \
        git \
        wget \
    ; \
    rm -rf /var/lib/apt/lists/*;

# Copy project composer.json and set the working directory.
COPY web/composer.json /var/www/html/composer.json
COPY web/composer.lock /var/www/html/composer.lock
WORKDIR /var/www/html
# Composer provided by base image

# Set composer env vars so all composer invocations use the same home and allow superuser
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/tmp/composer

# Composer global config
RUN composer config -g cache-dir /tmp/composer-cache
RUN composer config --no-plugins allow-plugins.composer/installers true --global
RUN composer config --no-plugins allow-plugins.cweagans/composer-patches true --global
RUN composer config --no-plugins allow-plugins.civicrm/composer-downloads-plugin true --global
RUN composer config --no-plugins allow-plugins.civicrm/composer-compile-plugin true --global

# Configure and install PHP extensions
RUN set -eux; \
    docker-php-ext-configure gd --with-jpeg --with-webp --with-avif --with-freetype; \
    docker-php-ext-install -j"$(nproc)" bcmath intl mysqli gd zip

# Install dependencies and run compile
# Run quick diagnostics; allow diagnose to fail without breaking the build
RUN composer --version && composer diagnose || true

# Install project dependencies. If the lockfile is out of date, fall back to composer update
# so automated builds don't fail when composer.lock and composer.json disagree.
RUN set -eux; \
    COMPOSER_COMPILE=0 composer install --no-interaction --no-dev --prefer-dist --no-progress || \
    (COMPOSER_COMPILE=0 composer update --no-interaction --no-dev --prefer-dist --no-progress)

# Run compile step (composer plugin command). This needs vendor present; do not ignore failures.
RUN COMPOSER_COMPILE=1 composer compile --all --no-interaction

# Download cv.phar in builder (builder has wget available) and make it executable so
# we can copy it into the minimal runtime image without running network commands there.
RUN wget -qO /usr/local/bin/cv https://download.civicrm.org/cv/cv.phar && chmod +x /usr/local/bin/cv

### Runtime stage
FROM drupal:11.1.8-php8.3-fpm

# Minimal runtime image: install only small runtime packages (curl + ca-certificates)
# and copy compiled PHP extensions and php conf from the builder stage. This keeps
# the final image small and free of build tools.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        # Runtime libraries required by the GD extension (ensure AVIF and other
        # image format libraries are present so the compiled gd extension can load)
        libpng-dev \
        libjpeg-dev \
        libfreetype6-dev \
        libwebp-dev \
        libavif-dev \
        libaom-dev \
        libheif-dev \
        zlib1g \
    ; \
    rm -rf /var/lib/apt/lists/*;

# Copy compiled PHP extensions and configuration from the builder stage so we don't
# need to rebuild extensions in the runtime image.
COPY --from=builder /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=builder /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d

# Copy composer.json and vendor from builder
COPY --from=builder /var/www/html/composer.json /var/www/html/composer.json
COPY --from=builder /var/www/html/composer.lock /var/www/html/composer.lock
COPY --from=builder --chown=www-data:www-data /var/www/html/vendor /var/www/html/vendor

# Copy cv CLI from builder (downloaded there) into the runtime image
COPY --from=builder /usr/local/bin/cv /usr/local/bin/cv
# Copy drupal entrypoint script (site init / autoinstall)
COPY docker/drupal-entrypoint.sh /usr/local/bin/drupal-entrypoint.sh
RUN chmod +x /usr/local/bin/drupal-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/drupal-entrypoint.sh"]

USER www-data

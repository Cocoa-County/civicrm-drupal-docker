### Builder stage
FROM php:8.3-fpm AS builder

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

# Use /opt/drupal/web as the project root during build. The runtime image will
# symlink /opt/drupal/web -> /var/www/html so the container and nginx both see
# the same files while allowing the compose volume to target /opt/drupal/web.
COPY web/composer.json /opt/drupal/web/composer.json
# COPY web/composer.lock /opt/drupal/web/composer.lock

# Install Composer (php image doesn't include it by default)
RUN set -eux; \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \
    composer --version

# Set composer env vars so all composer invocations use the same home and allow superuser
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/tmp/composer

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
FROM php:8.3-fpm

# Minimal runtime image: install only small runtime packages (curl + ca-certificates)
# and copy compiled PHP extensions and php conf from the builder stage. This keeps
# the final image small and free of build tools.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        # MySQL client program for CLI tasks and runtime MySQL client libraries
        # default-mysql-client \
        # Runtime libraries required by the GD extension (ensure AVIF and other
        # image format libraries are present so the compiled gd extension can load)
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

# Copy compiled PHP extensions and configuration from the builder stage so we don't
# need to rebuild extensions in the runtime image.
COPY --from=builder /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=builder /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d

# Copy composer.json and vendor from builder into /opt/drupal/web
COPY --from=builder /opt/drupal/web/composer.json /opt/drupal/web/composer.json
COPY --from=builder /opt/drupal/web/composer.lock /opt/drupal/web/composer.lock
COPY --from=builder --chown=www-data:www-data /opt/drupal/web/vendor /opt/drupal/web/vendor

# Ensure the runtime symlinks the drupal path into /var/www/html so other
# services (nginx) using /var/www/html will see the same files.
RUN ln -sfn /opt/drupal/web /var/www/html

# Copy cv CLI from builder (downloaded there) into the runtime image
COPY --from=builder /usr/local/bin/cv /usr/local/bin/cv

# Copy drupal entrypoint script (site init / autoinstall)
COPY docker/drupal-entrypoint.sh /usr/local/bin/drupal-entrypoint.sh
RUN chmod +x /usr/local/bin/drupal-entrypoint.sh

ENV PATH="/var/www/html/vendor/bin:${PATH}"

ENTRYPOINT ["/usr/local/bin/drupal-entrypoint.sh"]

USER www-data

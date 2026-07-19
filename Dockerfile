# Run composer to install dependencies
FROM composer:2 AS composer
WORKDIR /app/build-dependancies
COPY ./build-dependancies /app/build-dependancies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# From WordPress core
FROM wordpress:7.0-php8.5-fpm-alpine AS wp-core

# Use dunglas/frankenphp as the base image
FROM dunglas/frankenphp:1.12.5-php8-trixie

# add additional extensions here:
RUN install-php-extensions \
    gd \
    imagick \
    exif \
    zip \
    intl

# Copy dependencies
COPY --from=wp-core /usr/src/wordpress /app/public
COPY --from=composer /app/build-dependancies /app/build-dependancies
COPY --from=composer /app/build-dependancies/wp-content/plugins /app/public/wp-content/plugins

# Copy Caddyfile and php.ini
COPY ./config/Caddyfile /etc/frankenphp/Caddyfile
COPY ./config/php.ini /usr/local/etc/php/php.ini

ENV WORDPRESS_TARGET_DIR="/app/public"
ENV SQLITE_DIR="${WORDPRESS_TARGET_DIR}/wp-content/mu-plugins/sqlite-database-integration"

# Make sure mu-plugins directory exists
RUN mkdir -p "${WORDPRESS_TARGET_DIR}/wp-content/mu-plugins"

# Move SQLite Database Integration plugin to mu-plugins
RUN mv "${WORDPRESS_TARGET_DIR}/wp-content/plugins/sqlite-database-integration" "${WORDPRESS_TARGET_DIR}/wp-content/mu-plugins/sqlite-database-integration"

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Unzip plugins, ignoring errors
RUN unzip /app/build-dependancies/plugins/*.zip -d "${WORDPRESS_TARGET_DIR}/wp-content/plugins/" 2> /dev/null || true

# Tidy up
RUN rm -rf /app/build-dependancies/wp-content \
    && rm -rf /app/build-dependancies/plugins \
    && rm -rf /app/public/wp-content/themes/twentytwentyfour \
    && rm -rf /app/public/wp-content/themes/twentytwentythree \
    && rm -rf /app/public/wp-content/plugins/akismet \
    && rm /app/public/wp-content/plugins/hello.php

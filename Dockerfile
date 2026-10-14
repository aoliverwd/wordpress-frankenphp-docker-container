# Run composer to install dependencies
FROM composer:2 AS composer
WORKDIR /app/build-dependancies
COPY ./build-dependancies /app/build-dependancies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# From WordPress core
FROM wordpress:7.1-php8.5-fpm-alpine AS wp-core

# Use dunglas/frankenphp as the base image
FROM dunglas/frankenphp:1.13-php8-trixie

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

# Suppress deprecations for WP-CLI only
ENV WP_CLI_PHP_ARGS="-d error_reporting=24575"

# Ignore CLI pager
ENV PAGER=cat
# Or install less, terminal pager
# RUN apt-get update && apt-get install -y --no-install-recommends less \
#    && rm -rf /var/lib/apt/lists/*

# Make sure mu-plugins directory exists
RUN mkdir -p "${WORDPRESS_TARGET_DIR}/wp-content/mu-plugins"

# Move SQLite Database Integration plugin to mu-plugins
RUN mv "${WORDPRESS_TARGET_DIR}/wp-content/plugins/sqlite-database-integration" "${WORDPRESS_TARGET_DIR}/wp-content/mu-plugins/sqlite-database-integration"

# Install WP-CLI
RUN curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

# Install Composer
# RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Tidy up
RUN rm -rf /app/build-dependancies/wp-content \
    && rm -rf /app/build-dependancies/plugins \
    && rm -rf /app/public/wp-content/themes/twentytwentyfour \
    && rm -rf /app/public/wp-content/themes/twentytwentythree \
    && rm -rf /app/public/wp-content/plugins/akismet \
    && rm /app/public/wp-content/plugins/hello.php

# Create a non-root user
ARG USER=appuser

RUN <<-EOF
	# Use "adduser -D ${USER}" for alpine based distros
	useradd ${USER}
	# Remove default capability
	setcap -r /usr/local/bin/frankenphp
	# Give write access to /config/caddy and /data/caddy
	chown -R ${USER}:${USER} /config/caddy /data/caddy
EOF

USER ${USER}

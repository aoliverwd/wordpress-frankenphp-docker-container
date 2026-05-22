# Run composer to install dependencies
FROM composer:2 as composer
WORKDIR /app/build-dependancies
COPY ./build-dependancies /app/build-dependancies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# From WordPress core
FROM wordpress:7.0-php8.5-fpm-alpine AS wp-core

# Use dunglas/frankenphp as the base image
FROM dunglas/frankenphp:1.12.3-php8-alpine

# add additional extensions here:
RUN install-php-extensions \
    gd \
    exif \
    imagick \
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

# Tidy up
RUN rm -rf /app/build-dependancies/wp-content \
    && rm -rf /app/public/wp-content/themes/twentytwentyfour \
    && rm -rf /app/public/wp-content/themes/twentytwentythree \
    && rm -rf /app/public/wp-content/plugins/akismet \
    && rm /app/public/wp-content/plugins/hello.php
RUN mkdir -p "${WORDPRESS_TARGET_DIR}/wp-content/mu-plugins"
RUN mv "${WORDPRESS_TARGET_DIR}/wp-content/plugins/sqlite-database-integration" "${WORDPRESS_TARGET_DIR}/wp-content/mu-plugins/sqlite-database-integration"

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Set non-root user
ARG USER=appuser

RUN <<-EOF
	# Use "adduser -D ${USER}" for alpine based distros
	adduser -D ${USER}
	# Add additional capability to bind to port 80 and 443
	setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/frankenphp
	# Give write access to /config/caddy and /data/caddy
	chown -R ${USER}:${USER} /config/caddy /data/caddy
EOF

USER ${USER}

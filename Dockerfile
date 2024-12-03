# syntax=docker/dockerfile:1
FROM php:8.4-fpm-bookworm AS base

WORKDIR /app/

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN  --mount=type=bind,from=mlocati/php-extension-installer:latest,source=/usr/bin/install-php-extensions,target=/usr/local/bin/install-php-extensions \
    install-php-extensions \
    opcache \
    zip

COPY --link ./composer.* ./symfony.lock ./importmap.php ./tailwind.config.js /app/
COPY --link ./bin/ /app/bin/
COPY --link ./assets/ /app/assets/
COPY --link ./src/ /app/src/
COPY --link ./config/ /app/config/
COPY --link ./public/ /app/public/
COPY --link ./templates/ /app/templates/

RUN --mount=type=bind,from=composer/composer:2-bin,source=/composer,target=/usr/local/bin/composer \
    COMPOSER_ALLOW_SUPERUSER=1 \
    composer install \
    --no-autoloader \
    --no-cache \
    --no-dev \
    --no-progress \
    --no-scripts \
    --prefer-dist


FROM base AS development

RUN apt-get update && apt-get install -y --no-install-recommends \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

RUN echo 'APP_ENV=dev' > /app/.env
RUN --mount=type=bind,from=composer/composer:2-bin,source=/composer,target=/usr/local/bin/composer \
    COMPOSER_ALLOW_SUPERUSER=1 \
    composer install \
    --no-cache \
    --no-progress \
    --optimize-autoloader
RUN bin/console tailwind:build

COPY --link ./php-dev.ini /usr/local/etc/php/conf.d/dev.ini
COPY --link ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord"]


FROM base AS production

RUN --mount=type=bind,from=composer/composer:2-bin,source=/composer,target=/usr/local/bin/composer \
    mkdir -p var/cache var/log; \
    echo "<?php return ['APP_ENV' => 'prod'];" > /app/.env.local.php \
    && COMPOSER_ALLOW_SUPERUSER=1 APP_ENV-prod \
    composer dump-autoload \
    --classmap-authoritative \
    --no-dev; \
    COMPOSER_ALLOW_SUPERUSER=1 APP_ENV=prod composer run-script --no-dev post-install-cmd

RUN bin/console tailwind:build --minify; \
    bin/console asset-map:compile

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY --link ./php-prod.ini /usr/local/etc/php/conf.d/prod.ini
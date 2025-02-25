.PHONY: help build rebuild up down start stop destroy restart enter ps enable-xdebug disable-xdebug nginx-test

COMPOSE_CMD = docker compose
BUILD_CMD = $(COMPOSE_CMD) build --pull --parallel

nginx-test:
	docker run --rm -v './nginx.conf:/etc/nginx/conf.d/default.conf' nginxinc/nginx-unprivileged:stable-alpine sh -c 'nginx -tt'

help: ## Show the available commands.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build docker images
	$(BUILD_CMD) --build-arg BUILD_VERSION=1 --build-arg UID=$$(id -u) --build-arg GID=$$(id -g)

rebuild: ## Force rebuild of docker images from scratch
	$(BUILD_CMD) --build-arg BUILD_VERSION=1 --build-arg UID=$$(id -u) --build-arg GID=$$(id -g) --no-cache

logs: ## "make logs" show logs of a service. "make logs CONTAINER=node" will show logs for that container.
	$(COMPOSE_CMD) logs -f $(CONTAINER)

up: ## Build and start docker containers
	$(COMPOSE_CMD) up -d

start: ## Start docker containers
	$(COMPOSE_CMD) start

down: ## Remove docker containers
	$(COMPOSE_CMD) down

stop: ## Stop docker containers
	$(COMPOSE_CMD) stop

destroy: ## Delete docker images
	$(COMPOSE_CMD) down -v

ps: ## Show running docker containers for this project.
	$(COMPOSE_CMD) ps

restart: ## "make restart" restarts all services. "make restart CONTAINER=php" will restart the given service.
	$(COMPOSE_CMD) restart $(CONTAINER)

enter: ## Enter the PHP container
	$(COMPOSE_CMD) exec -it php ash

enable-xdebug: ## Enable the XDebug extension of PHP inside of the container
	$(COMPOSE_CMD) exec -i php sh -c "echo 'zend_extension=xdebug' > /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini"
	$(COMPOSE_CMD) restart php

disable-xdebug: ## Disable the XDebug extension of PHP inside of the container
	$(COMPOSE_CMD) exec -i php sh -c "echo '' > /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini"
	$(COMPOSE_CMD) restart php
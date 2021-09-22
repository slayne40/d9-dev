default: help

## help	:	Print commands help.
.PHONY: help
help : Makefile
	@sed -n 's/^##//p' $<

## clean	:	Print commands help.
.PHONY: clean
clean :
	rm composer.lock .editorconfig .gitattributes
	rm -rf private/ vendor/ web/
	mv .gitignore scripts/gitignore
	mv phploy.ini scripts/phploy.ini

DOCKER_STATE = $(shell systemctl is-active docker)
ifeq ($(DOCKER_STATE), active)

CURRENT_DIR = $(shell pwd)
PROJECT_NAME = $(shell basename $(CURRENT_DIR))

## ps	:	List running containers.
.PHONY: ps
ps:
	@docker ps --filter name='$(PROJECT_NAME)*'

## up	:	Start up containers.
.PHONY: up
up:
	@echo "Starting up containers for $(PROJECT_NAME)..."
	docker-compose up -d --remove-orphans

## down	:	Remove containers and their volumes.
##		You can optionally pass an argument with the service name to prune single container
##		down mariadb	: Prune `mariadb` container and remove its volumes.
##		down mariadb solr	: Prune `mariadb` and `solr` containers and remove their volumes.
.PHONY: down
down:
	@echo "Removing containers for $(PROJECT_NAME)..."
	@docker-compose down -v $(filter-out $@,$(MAKECMDGOALS))

## start	:	Start containers without updating.
.PHONY: start
start:
	@echo "Starting containers for $(PROJECT_NAME) from where you left off..."
	@docker-compose start

## stop	:	Stop containers.
.PHONY: stop
stop:
	@echo "Stopping containers for $(PROJECT_NAME)..."
	@docker-compose stop

CONTAINER_NAME = $(PROJECT_NAME)_php_1
CONTAINER_STATE = $(shell docker container inspect -f '{{.State.Status}}' $(CONTAINER_NAME) 2>/dev/null)
ifeq ($(CONTAINER_STATE), running)

COMPOSER_ROOT ?= /var/www/html
DRUPAL_ROOT ?= /var/www/html/web

## composer :	Executes `composer` command in a specified `COMPOSER_ROOT` directory (default is `/var/www/html`).
##		To use "--flag" arguments include them in quotation marks.
##		For example: make composer "update drupal/core --with-dependencies"
.PHONY: composer
composer:
	docker exec $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") composer --working-dir=$(COMPOSER_ROOT) $(filter-out $@,$(MAKECMDGOALS))

## drush	:	Executes `drush` command in a specified `DRUPAL_ROOT` directory (default is `/var/www/html/web`).
##		To use "--flag" arguments include them in quotation marks.
##		For example: make drush "watchdog:show --type=cron"
.PHONY: drush
drush:
	docker exec $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") vendor/bin/drush -r $(DRUPAL_ROOT) $(filter-out $@,$(MAKECMDGOALS))

## logs	:	View containers logs.
##		You can optinally pass an argument with the service name to limit logs
##		logs php	: View `php` container logs.
##		logs nginx php	: View `nginx` and `php` containers logs.
.PHONY: logs
logs:
	@docker-compose logs -f $(filter-out $@,$(MAKECMDGOALS))

# https://stackoverflow.com/a/6273809/1826109
%:
	@:

else
% :
		@echo "Error - Container not running"
endif

else
% :
		@echo "Error - Docker not active"
endif

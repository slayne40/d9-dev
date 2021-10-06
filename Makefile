PROJECT_NAME = d9

default: help

## help :	Print commands help.
.PHONY: help
help : Makefile
	@sed -n 's/^##//p' $<

## clean :	Reset project.
.PHONY: clean
clean :
	rm composer.lock .editorconfig .gitattributes
	rm -rf private/ vendor/ web/

## install :	Composer install / Drush site:install.
.PHONY: install
install:
	composer install
	composer run-script post-create-project-cmd

##
## FOR LINUX ONLY
##

CURRENT_DIR = $(shell pwd)
PROJECT_NAME = $(shell basename $(CURRENT_DIR))
COMPOSER_ROOT ?= /var/www/html
DRUPAL_ROOT ?= /var/www/html/web

## up :	Start up containers.
.PHONY: up
up:
	docker-compose -f .docker/docker-compose.yaml up -d --remove-orphans

## down :	Remove containers and their volumes.
##		You can optionally pass an argument with the service name to prune single container
##		down mariadb	: Prune `mariadb` container and remove its volumes.
##		down mariadb solr	: Prune `mariadb` and `solr` containers and remove their volumes.
.PHONY: down
down:
	@docker-compose -f .docker/docker-compose.yaml down -v $(filter-out $@,$(MAKECMDGOALS))

## composer :	Executes `composer` command in a specified `COMPOSER_ROOT` directory (default is `/var/www/html`).
##		To use "--flag" arguments include them in quotation marks.
##		For example: make composer "update drupal/core --with-dependencies"
.PHONY: composer
composer:
	docker exec $(shell docker ps --filter name='^/docker_php' --format "{{ .ID }}") composer --working-dir=$(COMPOSER_ROOT) $(filter-out $@,$(MAKECMDGOALS))

## drush :	Executes `drush` command in a specified `DRUPAL_ROOT` directory (default is `/var/www/html/web`).
##		To use "--flag" arguments include them in quotation marks.
##		For example: make drush "watchdog:show --type=cron"
.PHONY: drush
drush:
	docker exec $(shell docker ps --filter name='^/docker_php' --format "{{ .ID }}") vendor/bin/drush -r $(DRUPAL_ROOT) $(filter-out $@,$(MAKECMDGOALS))

# https://stackoverflow.com/a/6273809/1826109
%:
	@:

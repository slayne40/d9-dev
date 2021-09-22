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
  mv .gitignore scripts/gitignore
  mv phploy.ini scripts/phploy.ini

## install :	Composer install / Drush site:install.
.PHONY: install
install:
  composer install
  composer run-script post-create-project-cmd

# https://stackoverflow.com/a/6273809/1826109
%:
  @:

# Makefile for the presentation demo

CURRENT_DIR=$(shell \pwd)
DOCKER_BIN = $(shell \which docker)
VAULT_IMAGE_NAME = 'vault'
VAULT_IMAGE_VER = 'latest'
VAULT_IMAGE = $(VAULT_IMAGE_NAME):$(VAULT_IMAGE_VER)
VAULT_CONTAINER_NAME = 'vault-server'
PGSQL_IMAGE_NAME = 'crunchydata/crunchy-postgres'
PGSQL_IMAGE_VER = 'centos7-9.6-1.5'
PGSQL_IMAGE = $(PGSQL_IMAGE_NAME):$(PGSQL_IMAGE_VER)
PGSQL_CONTAINER_NAME = 'pgsql'

.PHONY: all clean build

all: clean build

build: pgsql-build vault-build

vault-build:
	@$(DOCKER_BIN) run \
		-p 8200:8200 \
		--name=$(VAULT_CONTAINER_NAME) \
		--cap-add=IPC_LOCK \
		-d $(VAULT_IMAGE)

pgsql-build:
	@$(DOCKER_BIN) run \
		-p 5432:5432 \
		-v pgsql:/pgdata \
		-v $(CURRENT_DIR)/postgres/bootstrap:/pgconf\
		--env-file=$(CURRENT_DIR)/postgres/env.list \
		--name=$(PGSQL_CONTAINER_NAME) \
		--hostname=$(PGSQL_CONTAINER_NAME) \
		-d $(PGSQL_IMAGE)

clean: 
	- @$(DOCKER_BIN) stop $(VAULT_CONTAINER_NAME)
	- @$(DOCKER_BIN) stop $(PGSQL_CONTAINER_NAME)
	- @$(DOCKER_BIN) rm $(VAULT_CONTAINER_NAME)
	- @$(DOCKER_BIN) rm $(PGSQL_CONTAINER_NAME)
	- @$(DOCKER_BIN) volume prune 

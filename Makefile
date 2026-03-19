.PHONY: create-network check-env deploy start stop generate-certificates-dev \
       server-init server-bootstrap server-clone server-deploy-env server-init-project server-status server-ssh

ifeq ($(wildcard .env),)
    $(info Creating .env file from .env.dist)
    $(shell cp .env.dist .env)
endif

include .env

SHELL = /bin/bash

TRAEFIK_USER := $(shell docker run --rm -i xmartlabs/htpasswd $(TRAEFIK_USER_USERNAME) $(TRAEFIK_USER_PASSWORD))
export TRAEFIK_USER

ifeq ($(ENV), dev)
    DOCKER_ENV_FLAG = -f docker-compose.dev.yaml
else ifeq ($(ENV), local)
    DOCKER_ENV_FLAG = -f docker-compose.dev.yaml
else ifeq ($(ENV), prod)
    DOCKER_ENV_FLAG = -f docker-compose.prod.yaml
else
    DOCKER_ENV_FLAG =
endif

create-network:
	docker network create --driver=bridge --attachable --internal=false reverse-proxy

check-env:
	@missing=0; \
	for key in $$(grep -oP '^[A-Z_]+(?==)' .env.dist); do \
		if ! grep -qP "^$$key=" .env 2>/dev/null; then \
			echo "Missing env var: $$key (defined in .env.dist but not in .env)"; \
			missing=1; \
		fi; \
	done; \
	if [ "$$missing" = "1" ]; then \
		echo ""; \
		echo "Fix: add the missing variable(s) to .env"; \
		exit 1; \
	fi; \
	echo "All env vars present."

deploy: check-env stop start

start:
	docker compose -f docker-compose.yaml $(DOCKER_ENV_FLAG) up --build -d

stop:
	docker compose -f docker-compose.yaml $(DOCKER_ENV_FLAG) down

generate-certificates-dev:
	if [ "$(ENV)" = "dev" ] || [ "$(ENV)" = "local" ]; then \
        mkcert -install && \
        mkcert -cert-file certs/cert.pem \
            -key-file certs/cert-key.pem \
            "*.local.com"; \
    fi


##########################################
##  Server Playbook (first-time setup)  ##
##########################################

SERVER ?= dedibox-1

## Full first-time server setup (all phases)
server-init: server-bootstrap server-clone server-deploy-env server-init-project

## Phase 0: system deps, deploy user, Docker (SSH as root)
server-bootstrap:
	@SERVER=$(SERVER) bash playbook/scripts/00-bootstrap.sh

## Phase 1: clone this repo on the server (SSH as deploy)
server-clone:
	@SERVER=$(SERVER) bash playbook/scripts/01-clone.sh

## Phase 2: decrypt SOPS locally → SCP .env file
server-deploy-env:
	@SERVER=$(SERVER) bash playbook/scripts/02-deploy-env.sh

## Phase 3: run init commands on the server
server-init-project:
	@SERVER=$(SERVER) bash playbook/scripts/03-init.sh

## Health check: docker ps on server
server-status:
	@SERVER=$(SERVER) bash playbook/scripts/status.sh

## Interactive SSH as deploy user
server-ssh:
	@SERVER=$(SERVER) bash playbook/scripts/ssh.sh

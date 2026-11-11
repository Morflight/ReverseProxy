.DEFAULT_GOAL := start
SHELL := /bin/bash
-include .env
ENV ?= dev
PROXY_NETWORK ?= reverse-proxy
export PROXY_NETWORK
ifeq ($(ENV),prod)
OVERLAY := docker-compose.prod.yaml
HOST_OVERLAY := $(wildcard hosts/$(TRAEFIK_HOSTNAME).yaml)
else ifneq ($(filter $(ENV),dev local),)
OVERLAY := docker-compose.dev.yaml
else
$(error ENV must be dev, local or prod)
endif
COMPOSE := docker compose -f docker-compose.yaml -f $(OVERLAY) $(addprefix -f ,$(HOST_OVERLAY))
.PHONY: create-network check-env start stop deploy smoke server-init server-bootstrap server-clone server-deploy-env server-init-project server-status server-ssh

ifeq ($(ENV),prod)
export TRAEFIK_USER_USERNAME TRAEFIK_USER_PASSWORD
# Hash only when starting a production stack. Compose receives the result through its environment.
PROD_AUTH = if [[ -z "$$TRAEFIK_USER" ]]; then : "$${TRAEFIK_USER_USERNAME:?Set dashboard user}" "$${TRAEFIK_USER_PASSWORD:?Set dashboard password}"; TRAEFIK_USER=$$(printf '%s\n' "$$TRAEFIK_USER_PASSWORD" | docker run --rm -i --entrypoint htpasswd httpd:2.4-alpine -niB "$$TRAEFIK_USER_USERNAME") || exit 1; export TRAEFIK_USER; fi;
endif

create-network:
	@docker network inspect "$(PROXY_NETWORK)" >/dev/null 2>&1 || docker network create "$(PROXY_NETWORK)" || docker network inspect "$(PROXY_NETWORK)" >/dev/null

check-env:
	@$(PROD_AUTH) $(COMPOSE) config --quiet

start deploy: create-network
	@$(PROD_AUTH) $(COMPOSE) up -d --remove-orphans

stop:
	@$(PROD_AUTH) $(COMPOSE) --profile '*' down

ifeq ($(ENV),prod)
SMOKE_URL ?=
else
SMOKE_URL ?= http://traefik.localhost:$(or $(HTTP_PORT),80)/dashboard/
endif
smoke:
	@test -n "$(SMOKE_URL)" || { echo 'Set SMOKE_URL to a public app health URL'; exit 1; }
	@./check.sh "$(SMOKE_URL)"


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

.PHONY: create-network deploy start stop generate-certificates-dev

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
else
    DOCKER_ENV_FLAG =
endif

create-network:
	docker network create --driver=bridge --attachable --internal=false reverse-proxy

deploy: stop start

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

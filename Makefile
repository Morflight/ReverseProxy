.PHONY: create-network deploy start stop generate-certificates-prod generate-certificates-dev

ifeq ($(wildcard .env),)
    $(info Creating .env file from .env.dist)
    $(shell cp .env.dist .env)
endif

include .env

SHELL = /bin/bash

TRAEFIK_USER := $(shell docker run --rm -i xmartlabs/htpasswd $(TRAEFIK_USER_USERNAME) $(TRAEFIK_USER_PASSWORD))
export TRAEFIK_USER

create-network:
	docker network create --driver=bridge --attachable --internal=false reverse-proxy

deploy: stop start

start:
	docker compose up --build -d

stop:
	docker compose down

generate-certificates-prod:
	if [ "$(ENV)" = "prod" ]; then \
		sudo docker run -it --rm --name certbot \
			-p "80:80" \
			-v "./etc/letsencrypt:/etc/letsencrypt" \
			certbot/certbot certonly; \
	fi

generate-certificates-dev:
	if [ "$(ENV)" = "dev" ] || [ "$(ENV)" = "local" ]; then \
        mkcert -install && \
        mkcert -cert-file certs/cert.pem \
            -key-file certs/cert-key.pem \
            $(TRAEFIK_DNS_LIST); \
    fi

Welcome to the documentation for this Reverse Proxy. This is a dockerized app that uses traefik to allow developers to work on various projects, all running in the background in the same time.

## Table of Contents

- [Prerequisites](#prerequisites)
- [How does it work ?](#how-does-it-work-?)
- [Getting Started](#getting-started)
- [Tools and Docs](#tools-and-docs)

## Prerequisites

- This guide is for Linux, MacOS and WSL2 installations
- Have Docker, Docker Compose and Make installed
```
sudo apt install docker docker-compose make
```

- Don't forget to add your user to the Docker group and restart your session for the changes to apply
```
sudo usermod -aG docker `whoami`
```
- For development environments, you also need mkcert to enable https

## How does it work ?

Traefik scans the DNS of your http requests and based on the configuration, reroutes you to the right app. This saves a lot of trouble when configuring your stack and allows seemless scaling without worrying too much about the port mapping.

You can also configure security options (enable basic auth or https) with the reverse proxy and easily extend this configuration to the rest of your apps.

**WARNING** Do not use *.dev. as your DNS, you will run into issues because it is protected.

## Getting Started

To get started, follow these steps:

1. **Start the reverse proxy's network**: run `make create-network` you should only do this once unless you prune your networks.
2. **Start Traefik**: run `make start`, you must do this every time you restart your machine
3. **Add a DNS record for Traefik**: edit your /etc/hosts file and add the following line: `127.0.0.1 traefik.local.com`
4. **Generate your certificates to enable https**: run `make generate-certificates-dev`
5. **Trust the certificates in your browser**:
   - **Linux**: `mkcert -install` (done automatically by step 4) handles it.
   - **WSL2**: the browser runs on Windows, so you need to install the root CA there too:
     ```bash
     # Copy the root CA to Windows
     cp "$(mkcert -CAROOT)/rootCA.pem" /mnt/c/Users/<your-windows-user>/rootCA.pem
     ```
     Then open **PowerShell as Administrator** on Windows and run:
     ```powershell
     certutil -addstore "Root" C:\Users\<your-windows-user>\rootCA.pem
     ```
     Restart your browser for the change to take effect.
   - **Firefox** (any OS): Firefox uses its own trust store. Go to `about:config` and set `security.enterprise_roots.enabled` to `true` to trust the system certificates.

And that's it. Traefik is now running. You can access the dashboard at (https://traefik.local.com)[https://traefik.local.com].
The default credentials are admin:admin, but you can modify them by tweaking the .env file.

Every time you run `make start` on your other apps, you should see new elements in the Router section. Don't forget to add DNS records for the other apps as well.


## Tools and Docs

- [Traefik](https://doc.traefik.io/traefik/)
- [Docker](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Make](https://www.gnu.org/software/make/manual/make.html)
- [mkcert](https://github.com/FiloSottile/mkcert)

# Encrypted Environment Files

Each deploy target has its own SOPS-encrypted YAML file: `<server-name>.enc.yaml`.
The `.yaml` extension is required — SOPS uses it to detect the format and encrypt per-key.
The server name must match the `name` field in `.github/deploy-targets.json`.

## Prerequisites

- [SOPS](https://github.com/getsops/sops) installed locally
- [age](https://github.com/FiloSottile/age) installed locally
- Age private key available (e.g. in `~/.config/sops/age/keys.txt` or via `SOPS_AGE_KEY` env var)

## Setup (once)

```bash
# Generate an age keypair
age-keygen -o key.txt

# Copy the public key (age1...) into .sops.yaml
# Add the private key as SOPS_AGE_KEY in GitHub Actions secrets
# Move the private key to ~/.config/sops/age/keys.txt for local use
mkdir -p ~/.config/sops/age
mv key.txt ~/.config/sops/age/keys.txt
```

## Create a new encrypted env file

```bash
sops envs/dedibox-1.enc.yaml
# This opens $EDITOR — write your .env content, save, and SOPS encrypts it
```

## Edit an existing encrypted env file

```bash
sops envs/dedibox-1.enc.yaml
# Opens decrypted in $EDITOR — edit, save, SOPS re-encrypts automatically
```

## View without editing

```bash
sops -d envs/dedibox-1.enc.yaml
```

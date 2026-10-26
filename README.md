# SearXNG Local

The official SearXNG container, configured for local HTML and JSON searches at **https://searxng.test**. This repository owns only SearXNG. Shared HTTPS, certificates, hosts helpers, and the Caddy container live in [Caddy Local](https://github.com/rohandhamapurkar/caddy-local).

## Requirements

- Docker Desktop running Linux containers and Docker Compose.
- Git and PowerShell on Windows, or built-in Bash and OpenSSL on macOS.
- [Caddy Local](https://github.com/rohandhamapurkar/caddy-local) initialized and running, with its local CA trusted and `searxng.test` mapped to localhost.

Clone the repositories as siblings, for example `NodeJS/caddy-local`, `NodeJS/searxng`, and optionally `NodeJS/pihole`. Set up Caddy Local first to create the external `local-apps` network.

## Windows

```powershell
git clone https://github.com/rohandhamapurkar/searxng-local.git searxng
cd searxng
powershell -NoProfile -ExecutionPolicy Bypass -File .\initialize.ps1
docker compose up -d
```

## macOS

Install and launch Docker Desktop for your Mac. Set up Caddy Local with its `setup-macos.sh`, then:

```bash
git clone https://github.com/rohandhamapurkar/searxng-local.git searxng
cd searxng
bash ./setup-macos.sh
```

The app initializer generates ignored `config/settings.yml` with a random secret and preserves existing settings. No administrator access is required for the app stack; hosts and trust setup are handled by Caddy Local. macOS shell syntax and settings generation were checked from Linux; macOS Keychain operations are documented in Caddy Local and have not been tested on a Mac here.

## Browser search

Use `https://searxng.test/search?q=%s` as the search URL. In Chrome or Edge, add it under Manage search engines, then choose Make default. In Opera, add it with keyword `sx` and use `sx search terms`.

## Management

```text
docker compose ps
docker compose logs --tail 100
docker compose restart searxng
docker compose stop
docker compose up -d
```

Edit `config/settings.yml`, then restart SearXNG. Update with `docker compose pull`, then `docker compose up -d`. This stack exposes no host ports; Caddy reaches `searxng:8080` on `local-apps`. Stopping SearXNG does not stop the proxy or Pi-hole.

The JSON API is enabled:

```powershell
Invoke-RestMethod 'https://searxng.test/search?q=searxng&format=json'
```

Queries go to enabled upstream search engines, which may time out, rate-limit, or require CAPTCHAs. Choose engines in Preferences > Engines. Local HTTPS does not hide queries from those providers. Rate limiting is disabled for this localhost-only deployment.

## Migration from the combined stack

Earlier versions included Caddy in this repository. Before using this version, move Caddy's configuration and persistent CA to Caddy Local, following that repository's migration guidance. Keep the existing SearXNG project name and data volume to retain the app's cache. Existing `config/settings.yml` is preserved. Caddy's hosts and trust helpers now belong to Caddy Local.

If you still use the old `searxng.com` hostname, remove only its marked local hosts entry, use Caddy Local's hosts helper to add `searxng.test`, and change the existing settings base URL to `https://searxng.test/`. Update browser search URLs and bookmarks too.

## Removal

`docker compose down` removes this app's container while preserving settings and data. `down -v` also deletes its cache volume. Caddy's CA and containers are managed separately. Never commit live settings or secret keys.

Official reference: https://docs.searxng.org/admin/installation-docker

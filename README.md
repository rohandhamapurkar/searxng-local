# Local SearXNG with HTTPS on Windows

Run the official SearXNG container behind Caddy at **https://searxng.com**, with a locally trusted certificate. Docker publishes ports only on `127.0.0.1`. This repository contains deployment configuration, not SearXNG source code.

## Requirements

- Windows with Docker Desktop running Linux containers and Docker Compose.
- PowerShell and Git.
- Available local ports 80, 443 and 8888.
- Administrator access for the one-time Windows hosts entry.

## Setup

Clone this repository and run commands from its folder:

```powershell
git clone https://github.com/rohandhamapurkar/searxng-local.git
cd searxng-local
powershell -NoProfile -ExecutionPolicy Bypass -File .\initialize.ps1
```

The initializer creates an ignored `config/settings.yml` with a cryptographically random secret. Existing settings are preserved.

In an **administrator PowerShell**, run `set-local-host.ps1` from this repository. It backs up the hosts file, adds `127.0.0.1 searxng.com`, and flushes the DNS cache. It refuses to overwrite a conflicting entry.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\set-local-host.ps1
```

Back in your regular PowerShell:

```powershell
docker compose up -d
powershell -NoProfile -ExecutionPolicy Bypass -File .\trust-local-ca.ps1
```

If the certificate is not ready yet, wait a few seconds and rerun the trust script. It exports only the public root certificate and trusts it for the current Windows user. Each installation generates its own CA. Caddy stores private keys in its Docker data volume and renews server certificates automatically.

Open **https://searxng.com**. Restart browsers if they cached a certificate error. The HTTP addresses `http://searxng.com` and `http://localhost:8888` redirect to HTTPS. SearXNG's port 8080 is accessible inside Docker only.

The hosts entry overrides the public `searxng.com` domain on this machine. This setup does not require owning that domain or obtaining a public certificate. The certificate is trusted only on devices where you install this instance's CA. Keep the CA private key private.

## Browser search

Use this search URL template:

```text
https://searxng.com/search?q=%s
```

- Chrome: open `chrome://settings/searchEngines`, add a site search named SearXNG with shortcut `sx` and the URL above, then choose **Make default** from its menu.
- Edge: open `edge://settings/searchEngines`, add the same entry and choose **Make default**. Set new-tab searches to use the address bar if desired.
- Opera: add a custom search with keyword `sx`, then type `sx search terms`. Default provider choices may be restricted.

## Management

```powershell
docker compose ps
docker compose logs --tail 100
docker compose stop
docker compose up -d
```

To update images, run `docker compose pull`, then `docker compose up -d`. Images use moving tags; review upstream changes before updating.

Edit `config/settings.yml` to change search settings, then run `docker compose restart searxng`. Docker Desktop must be running. Containers restart with Docker unless explicitly stopped.

The JSON API is enabled:

```powershell
Invoke-RestMethod 'https://searxng.com/search?q=searxng&format=json'
```

HTTPS protects browser-to-local-service traffic. Queries still go to enabled upstream search engines, which may time out, rate-limit, or require CAPTCHAs. Select providers in Preferences > Engines. Rate limiting is disabled for this localhost-only deployment.

## Removal

`docker compose down` removes the containers and network while retaining settings and data. Do not use `down -v` unless you intend to delete persistent data, including the CA. If you regenerate the CA, remove the old root from Windows and trust the new one.

To remove the installed root, open `certmgr.msc`, go to **Trusted Root Certification Authorities > Certificates**, and remove the certificate whose thumbprint matches `caddy-local-root.crt`. Remove the marked SearXNG line from the Windows hosts file in an administrator editor if you no longer want the local domain mapping.

Live settings, exported certificates, and keys are ignored by Git. Never commit runtime secrets or Docker volume contents.

## References

- [SearXNG container documentation](https://docs.searxng.org/admin/installation-docker)
- [Caddy automatic HTTPS and local CA](https://caddyserver.com/docs/automatic-https)

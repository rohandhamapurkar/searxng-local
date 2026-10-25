# Local SearXNG with HTTPS on Windows and macOS

Run the official SearXNG container behind Caddy at **https://searxng.test**, with a locally trusted certificate. Docker publishes ports only on `127.0.0.1`. This repository contains deployment configuration, not SearXNG source code.

## Requirements

- Windows or macOS with Docker Desktop running Linux containers and Docker Compose.
- Git, plus PowerShell on Windows or the built-in Bash and OpenSSL on macOS.
- Available local ports 80, 443 and 8888.
- Administrator access for the one-time hosts entry.

## Windows setup

Clone this repository and run commands from its folder:

```powershell
git clone https://github.com/rohandhamapurkar/searxng-local.git
cd searxng-local
powershell -NoProfile -ExecutionPolicy Bypass -File .\initialize.ps1
```

The initializer creates an ignored `config/settings.yml` with a cryptographically random secret. Existing settings are preserved.

In an **administrator PowerShell**, run `set-local-host.ps1` from this repository. It backs up the hosts file, adds `127.0.0.1 searxng.test`, and flushes the DNS cache. It refuses to overwrite a conflicting entry.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\set-local-host.ps1
```

Back in your regular PowerShell:

```powershell
docker compose up -d
powershell -NoProfile -ExecutionPolicy Bypass -File .\trust-local-ca.ps1
```

If the certificate is not ready yet, wait a few seconds and rerun the trust script. It exports only the public root certificate and trusts it for the current Windows user. Each installation generates its own CA. Caddy stores private keys in its Docker data volume and renews server certificates automatically.

Open **https://searxng.test**. Restart browsers if they cached a certificate error. The HTTP addresses `http://searxng.test` and `http://localhost:8888` redirect to HTTPS. SearXNG's port 8080 is accessible inside Docker only.

The `.test` domain is reserved for testing, so this hostname does not override a public domain. This setup uses a local CA and does not require a public certificate. The certificate is trusted only on devices where you install this instance's CA. Keep the CA private key private.

## macOS setup

Install and launch [Docker Desktop for Mac](https://docs.docker.com/desktop/setup/install/mac-install/), choosing the download for your Mac's processor. Wait until Docker is running. If Git is missing, run `xcode-select --install` to install Apple's command line tools.

In Terminal, clone the repository and run the setup script **without sudo**:

```bash
git clone https://github.com/rohandhamapurkar/searxng-local.git
cd searxng-local
bash ./setup-macos.sh
```

The script checks Docker, generates ignored local settings with a random secret, requests `sudo` only to back up and update `/etc/hosts`, flushes macOS DNS caches, starts the containers, waits for Caddy's CA, and installs the public CA certificate in your **login Keychain** with SSL trust. macOS may display an authorization prompt. Docker and certificate export run as your regular user. Existing settings are preserved; conflicting hosts entries stop the hosts step without changing the file.

You can also run the steps individually from the repository folder:

```bash
bash ./initialize.sh
sudo bash ./set-local-host.sh
docker compose up -d
bash ./trust-local-ca.sh
```

Open **https://searxng.test**. Restart browsers if needed. If trust installation is denied or the browser still reports an untrusted certificate, open Keychain Access, import `caddy-local-root.crt` into the login Keychain if absent, open that certificate, and set its SSL trust to **Always Trust**. See [Apple's certificate trust instructions](https://support.apple.com/guide/keychain-access/change-the-trust-settings-of-a-certificate-kyca11871/mac). Browser-specific certificate stores may need a separate import.

Verify with macOS's built-in curl, without disabling certificate validation:

```bash
/usr/bin/curl --fail --show-error https://searxng.test/ -o /dev/null
/usr/bin/curl --fail --show-error 'https://searxng.test/search?q=searxng&format=json'
```

If Docker cannot bind a privileged port, review Docker Desktop's advanced settings for privileged port mapping. If a port is already occupied, stop the conflicting service before starting this stack. Both platforms use the same Compose file and Caddy configuration.

## Upgrading from the previous hostname

If you used the earlier `searxng.com` setup, remove only its marked `# SearXNG local test` line from your hosts file with administrator access. Run the hosts script for your platform to add `searxng.test`, change the base URL in your existing ignored `config/settings.yml` to `https://searxng.test/`, and run `docker compose restart`. Keep the Caddy data volume: the existing trusted CA will issue a certificate for the new name. Update browser search URLs and bookmarks to `https://searxng.test`. A browser may retain the previous permanent localhost redirect; navigate directly to the new HTTPS URL if so.

## Browser search

Use this search URL template:

```text
https://searxng.test/search?q=%s
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
Invoke-RestMethod 'https://searxng.test/search?q=searxng&format=json'
```

HTTPS protects browser-to-local-service traffic. Queries still go to enabled upstream search engines, which may time out, rate-limit, or require CAPTCHAs. Select providers in Preferences > Engines. Rate limiting is disabled for this localhost-only deployment.

## Removal

`docker compose down` removes the containers and network while retaining settings and data. Do not use `down -v` unless you intend to delete persistent data, including the CA. If you regenerate the CA, remove the old root from your operating system's trust store and trust the new one.

To remove the installed root, open `certmgr.msc`, go to **Trusted Root Certification Authorities > Certificates**, and remove the certificate whose thumbprint matches `caddy-local-root.crt`. Remove the marked SearXNG line from the Windows hosts file in an administrator editor if you no longer want the local domain mapping.

On macOS, use Keychain Access to remove the matching CA from your login Keychain (including its trust settings), and remove the marked SearXNG entry from `/etc/hosts` with `sudo` if no longer needed. Compare the SHA-256 fingerprint with `openssl x509 -in caddy-local-root.crt -noout -fingerprint -sha256` so you remove only this instance's CA. Flush DNS with `sudo dscacheutil -flushcache` and `sudo killall -HUP mDNSResponder` after editing hosts. Trust the new CA if its data volume is ever regenerated.

Live settings, exported certificates, and keys are ignored by Git. Never commit runtime secrets or Docker volume contents.

## Validation

The Windows deployment was verified with trusted HTTPS requests and live search results. The shell scripts passed Bash syntax checks and Linux smoke checks for random secret generation, private settings permissions, paths with spaces, preservation of existing settings, and rejection of non-macOS hosts/trust/setup execution. The macOS Keychain and DNS commands have not been run on a Mac in this environment.

## References

- [SearXNG container documentation](https://docs.searxng.org/admin/installation-docker)
- [Caddy automatic HTTPS and local CA](https://caddyserver.com/docs/automatic-https)

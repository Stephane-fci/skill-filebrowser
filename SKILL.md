---
name: filebrowser
description: "Install and configure FileBrowser as a web-based file manager for an AI agent workspace. Gives humans a browser UI to view, edit, and download files the agent produces — without SSH access or technical knowledge. Use when: (1) setting up FileBrowser from scratch on a VPS, (2) adding users or changing permissions, (3) configuring security (Cloudflare Access, fail2ban), (4) sharing direct file URLs with humans, (5) troubleshooting FileBrowser issues. NOT for: general file operations (use read/write/edit tools), or when the human just needs to see a single file (send it directly)."
---

# FileBrowser — Agent Workspace File Manager

Give your human a web UI to browse, edit, and download files you produce — without SSH or technical knowledge.

**What it is:** FileBrowser is a self-hosted web file manager. Install it, point it at your workspace, and your human gets a clean browser interface at a URL like `workspace.example.com/filebrowser`.

**Why agents need this:** You create files (research, reports, configs, images). Your human needs to see them. Instead of copy-pasting content into chat or attaching files, give them a URL. They browse, you keep working.

## Prerequisites

Before starting, confirm with your human:
- [ ] A VPS with root/sudo access (where the agent workspace lives)
- [ ] A domain with DNS managed by Cloudflare (for SSL + security)
- [ ] Nginx installed (`sudo apt install nginx` if not)
- [ ] The workspace path and the OS user the agent runs as

## Step 1: Install FileBrowser

Run the install script. It downloads the binary, creates the database, configures defaults, and creates a systemd service.

```bash
sudo bash scripts/install.sh <workspace_path> <service_user> <port> [base_url]
```

**Example:** Agent workspace at `/home/myagent/workspace`, runs as `myagent`, port 8085, served at `/filebrowser`:
```bash
sudo bash scripts/install.sh /home/myagent/workspace myagent 8085 /filebrowser
```

The script sets secure defaults:
- Signup disabled, execute disabled, delete disabled for new users
- Dotfiles hidden, token expiration 24h, mosaic view, A→Z sorting
- Listens on 127.0.0.1 only (not exposed without Nginx)

If the install script is unavailable, perform manual installation:
1. `curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | sudo bash`
2. `sudo mkdir -p /etc/filebrowser`
3. `sudo /usr/local/bin/filebrowser config init --database /etc/filebrowser/filebrowser.db`
4. Configure with `filebrowser config set` flags (see install script for all flags)
5. Create systemd service (see install script for template)

**Important:** Use the **original FileBrowser** (`filebrowser/filebrowser`), NOT the Quantum fork (`gtsteffaniak/filebrowser`). Quantum's standalone binary panics without Docker because it doesn't bundle the frontend. The original binary is fully self-contained.

## Step 2: Create Users

Plan the user strategy with your human. Common patterns:

| User | Scope | Permissions |
|------|-------|------------|
| admin | `/` | admin, all permissions |
| collaborator | `/` | create, modify, share, download (no admin, no execute) |
| viewer | `/` | download only |

For restricted access, set scope to a subfolder (e.g. `/shared` or `/output`). Users can only see files within their scope.

Create users (service must be stopped first):
```bash
sudo systemctl stop filebrowser
sudo /usr/local/bin/filebrowser users add <username> <password> --database /etc/filebrowser/filebrowser.db --scope <scope>
sudo systemctl start filebrowser
```

Set specific permissions per user:
```bash
sudo systemctl stop filebrowser
sudo /usr/local/bin/filebrowser users update <username> --database /etc/filebrowser/filebrowser.db \
    --perm.admin=false --perm.execute=false --perm.create=true --perm.rename=false \
    --perm.modify=true --perm.delete=false --perm.share=true --perm.download=true \
    --hideDotfiles=true --viewMode="mosaic" --sorting.asc=true
sudo systemctl start filebrowser
```

**Critical:** Always disable `execute` globally. It allows arbitrary shell commands.

**Critical:** Consider disabling `rename` for non-admin users. Renaming files breaks agent references (paths in configs, indexes, roadmaps). If someone renames a file, any agent code referencing the old path breaks silently.

Store credentials in a JSON file outside the workspace:
```json
{
  "url": "https://subdomain.example.com/filebrowser",
  "users": {
    "admin": {"scope": "/", "password": "<generated>"},
    "collaborator": {"scope": "/", "password": "<generated>"}
  }
}
```

## Step 3: Configure Nginx

Read `references/nginx-configs.md` for templates.

Two patterns:
- **Subpath** (recommended): `workspace.example.com/filebrowser` — leaves room for other tools on the same subdomain
- **Subdomain**: `files.example.com` — simpler but uses a whole subdomain

For subpath, set baseURL in FileBrowser config:
```bash
sudo systemctl stop filebrowser
sudo /usr/local/bin/filebrowser config set --database /etc/filebrowser/filebrowser.db --baseURL /filebrowser
sudo systemctl start filebrowser
```

Generate a self-signed SSL cert (sufficient for Cloudflare Full mode):
```bash
sudo mkdir -p /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/filebrowser.key \
    -out /etc/nginx/ssl/filebrowser.crt \
    -subj "/CN=subdomain.example.com"
```

Create the Nginx config, enable it, test, reload:
```bash
sudo ln -sf /etc/nginx/sites-available/<config> /etc/nginx/sites-enabled/<config>
sudo nginx -t && sudo nginx -s reload
```

## Step 4: DNS + Cloudflare

Create a Cloudflare DNS A record pointing the subdomain to the VPS IP (proxied).

```bash
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
    -H "Authorization: Bearer $CF_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"type":"A","name":"subdomain","content":"<VPS_IP>","proxied":true,"ttl":1}'
```

Set Cloudflare SSL mode to **Full** (not Full Strict — self-signed cert won't pass strict validation).

Open firewall ports:
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

## Step 5: Security Hardening

Read `references/security.md` for the full security reference.

### 5a: fail2ban (brute force protection)

Run the fail2ban setup script:
```bash
sudo bash scripts/setup-fail2ban.sh [max_retry] [ban_time_seconds]
# Default: 5 retries, 3600s (1 hour) ban
```

### 5b: Cloudflare Access (email verification wall)

Adds an email verification step before anyone can see the login page. **Ask your human for a Cloudflare API token with Zero Trust permissions at the start** — this avoids walking them through the dashboard manually.

Token permission needed: **Account → Access: Apps and Policies → Edit**

With the token, create via API (see `references/security.md` for full API examples).

Without the token, guide the human through the Cloudflare dashboard:
1. https://one.dash.cloudflare.com → Zero Trust (activate free plan if needed — requires a payment method even though it's $0)
2. Access → Applications → Add Application → Self-hosted
3. Enter subdomain + domain + path
4. Create an Allow policy with authorized email addresses
5. Save

**Gotcha:** The Zero Trust free plan requires a payment method even though it costs nothing. Warn the human upfront so they're not surprised.

**Gotcha:** Cloudflare Zero Trust requires a **separate API token** from the standard DNS/Pages token. Ask for it at the START of setup, not after walking the human through dashboard clicks.

## Step 6: Configure Settings

Apply recommended settings (stop service, apply, restart):

```bash
sudo systemctl stop filebrowser
DB="/etc/filebrowser/filebrowser.db"

sudo /usr/local/bin/filebrowser config set --database "$DB" \
    --branding.name "My Workspace" \
    --tokenExpirationTime "24h" \
    --hideDotfiles=true \
    --sorting.asc=true \
    --viewMode="mosaic" \
    --perm.rename=false \
    --perm.execute=false \
    --perm.delete=false

sudo systemctl start filebrowser
```

**Note:** `config set` changes only apply to NEW users. Existing users must be updated individually with `filebrowser users update`.

## Step 7: Update Agent Knowledge

Add FileBrowser to the agent's tools documentation so it knows about the tool and can share direct URLs:

```markdown
### FileBrowser
- **URL:** https://subdomain.example.com/filebrowser
- **Credential:** path to credentials JSON
- **Service:** `sudo systemctl status filebrowser`
- **Direct file URL pattern:** `https://subdomain.example.com/filebrowser/files/{path}`
- After creating/updating files, include the direct URL in messages.
```

## Sharing Files

Direct URL pattern: `https://{host}/{base_url}/files/{path_relative_to_user_scope}`

**⚠️ CRITICAL: URLs are relative to the user's scope, NOT the workspace root.**

If a user's scope is `/output`, they see `/output` as their root `/`. So:
- **User with scope `/`**: `/filebrowser/files/output/report.md`
- **User with scope `/output`**: `/filebrowser/files/report.md` (NO `output/` prefix!)

Sharing a `/files/output/report.md` URL with a user scoped to `/output` will fail — FileBrowser looks for `/output/output/report.md` which doesn't exist → "This location can't be reached."

**Simplest approach:** Give all users scope `/` with `hideDotfiles=true`. URLs are identical for everyone. Restrict scope only for untrusted or external users.

Markdown, images, PDFs, and text files render inline. Users click, read, done.

After creating or updating a file, include the direct URL in your message: *"Report complete — view it here: [URL]"*. A link is 10x more useful than "I saved it to the workspace."

## Onboarding New Users

When your human asks you to give someone access, follow this sequence:

1. **Explain what it is** — "A web file browser connected to my workspace. You can browse, read, and download anything I create."
2. **Share the URL**
3. **Warn about Cloudflare Access** (if enabled) — "You'll see an email verification screen first. Enter your email, check inbox and spam, enter the code."
4. **Share credentials** — Username and password
5. **Explain permissions** — What they can and can't do
6. **Share a specific useful link** — Don't just say "go browse." Give a direct link to something relevant.

**Common issues:**
- "I didn't get the code" → Email not in Cloudflare Access allow list. Add it.
- "This location can't be reached" → URL doesn't match user scope. See Sharing Files section.
- "I can't edit" → Check user permissions with `users update` CLI.

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| "000 No connection" in folder view | Calculating large folder sizes | Cosmetic — files still accessible |
| Database locked / timeout on CLI | Service holds the lock | Stop service → CLI command → start service |
| Login page not showing | Cloudflare Access redirect | Verify email first, then login |
| `baseURL` not working | Config not applied | Stop → `config set --baseURL` → start |
| Quantum binary panics | Missing embedded frontend | Use original FileBrowser, not Quantum fork |
| File renamed, agent broke | Rename permission enabled | `users update <user> --perm.rename=false` |
| "This location can't be reached" | URL/scope mismatch | Build URL relative to user's scope, not workspace root |
| Cloudflare code not arriving | Email not in allow list | Add email to Cloudflare Access policy |
| Cloudflare code in spam | Normal behavior | Check spam/junk folder |

## Self-Improvement

After every execution of this skill, evaluate:
1. Did the installation complete without errors?
2. Were there environment-specific issues (OS version, nginx version, permissions)?
3. Did the human struggle with any step?
4. Were there security concerns not covered?

Update this skill with findings:
- Fix incorrect commands or outdated URLs
- Add new gotchas and their solutions
- Update security references if new CVEs are discovered
- Append findings to Lessons Learned below

## Lessons Learned

- **Use original FileBrowser, not Quantum.** Quantum fork has better features (OIDC, search) but the standalone binary panics without Docker — doesn't embed the frontend. Original binary is self-contained.
- **`config set` defaults only affect new users.** Existing users must be updated individually with `users update`. Not obvious — causes confusion when settings "don't apply."
- **Database locks when service is running.** All CLI operations (`users add`, `users update`, `config set`) require stopping the service first. SQLite (BoltDB) doesn't support concurrent access.
- **`viewMode` only accepts "list" or "mosaic" via CLI.** The web UI shows "mosaic gallery" as an option but the CLI rejects it.
- **Rename permission breaks agent references.** Agents reference files by path. A rename silently breaks those references. Disable rename for non-admin users.
- **Cloudflare Zero Trust requires a separate API token.** Standard DNS/Pages tokens don't include Zero Trust. Ask the human for a dedicated token with "Access: Apps and Policies - Edit" at the START of setup.
- **Cloudflare free Zero Trust plan requires a payment method.** $0 plan but card required. Warn upfront.
- **No per-folder permissions.** Permissions are per-user, applied uniformly within scope. The "Rules" system can block paths but can't make them read-only. Use scope for visibility control.
- **Self-signed certs work with Cloudflare Full mode.** No Let's Encrypt needed when using Cloudflare proxy.
- **fail2ban uses journald backend.** FileBrowser logs to journald, not files. Use `backend = systemd` and `journalmatch = _SYSTEMD_UNIT=filebrowser.service`.
- **FileBrowser runs as the agent user.** Edits via FileBrowser are indistinguishable from agent edits in git — same OS user.
- **URLs are relative to user scope.** If a user's scope is `/subfolder`, URLs must omit that prefix. Sharing a full-path URL to a scoped user causes double-path lookups → 404. **Simplest fix: give all trusted users scope `/`.**
- **Scope `/` with `hideDotfiles=true` is the simplest setup.** Restricting scope causes URL mismatches and complexity. For trusted users, full scope with hidden dotfiles is simpler and less error-prone. Reserve restricted scopes for untrusted/external users.
- **Onboarding flow matters.** Don't dump credentials. Walk through: what it is → URL → Cloudflare warning → credentials → permissions → one useful direct link. The Cloudflare email step confuses people who expect a normal login page.
- **Share direct links proactively.** After creating files, include the FileBrowser URL in the chat message. "Here's the report" + a link is far more useful than "I saved it to the workspace."

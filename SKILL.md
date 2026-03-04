---
name: filebrowser
description: "Install and configure FileBrowser as a web-based file manager for an AI agent workspace. Gives humans (team members, clients, collaborators) a browser UI to view, edit, and download files the agent produces — without SSH access or technical knowledge. Use when: (1) setting up FileBrowser from scratch on a VPS, (2) adding users or changing permissions, (3) configuring security (Cloudflare Access, fail2ban), (4) sharing direct file URLs with team members, (5) troubleshooting FileBrowser issues. NOT for: general file operations (use read/write/edit tools), or when the human just needs to see a file (send it directly)."
---

# FileBrowser — Agent Workspace File Manager

Give your human team a web UI to browse, edit, and download files you produce — without SSH or technical knowledge.

**What it is:** FileBrowser is a self-hosted web file manager. You install it, point it at your workspace, and your human gets a clean browser interface at a URL like `workspace.example.com/filebrowser`.

**Why agents need this:** You create files (research, reports, configs, images). Your human and their team need to see them. Instead of copy-pasting content into chat or attaching files, give them a URL. They browse, you keep working.

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

Plan the user strategy with your human. Recommended setup:

| User | Scope | Purpose | Permissions |
|------|-------|---------|------------|
| admin | `/` | Human owner — full access | admin, create, rename, modify, delete, share, download |
| team | `/spaces` or `/shared` | Team members — edit shared files | create, modify, share, download |
| viewer | `/` | Read-only observers | download only |

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

**Critical:** Always disable `rename` for non-admin users. Renaming files breaks agent references (paths in roadmaps, skills, indexes). The agent references files by path — if someone renames `INDEX.md` to `index.md`, things break silently.

**Critical:** Always disable `execute` globally. It allows arbitrary shell commands.

Store credentials in a JSON file outside the workspace:
```json
{
  "url": "https://subdomain.example.com/filebrowser",
  "users": {
    "admin": {"scope": "/", "password": "<generated>"},
    "team": {"scope": "/spaces", "password": "<generated>"},
    "viewer": {"scope": "/", "password": "<generated>"}
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

This adds an email verification step before anyone can see the login page. **Ask your human for a Cloudflare API token with Zero Trust permissions early** — this avoids having to walk them through the dashboard manually.

Token permission needed: **Account → Access: Apps and Policies → Edit**

With the token, create via API (see `references/security.md` for full API examples).

Without the token, guide the human through the Cloudflare dashboard:
1. https://one.dash.cloudflare.com → Zero Trust (activate free plan if needed)
2. Access → Applications → Add Application → Self-hosted
3. Enter subdomain + domain + path
4. Create an Allow policy with team email addresses
5. Save

**Note:** Cloudflare requires a payment method even for the free Zero Trust plan.

## Step 6: Configure Settings

Apply recommended settings (stop service, apply, restart):

```bash
sudo systemctl stop filebrowser
DB="/etc/filebrowser/filebrowser.db"

sudo /usr/local/bin/filebrowser config set --database "$DB" \
    --branding.name "Workspace Name" \
    --tokenExpirationTime "24h" \
    --hideDotfiles=true \
    --sorting.asc=true \
    --viewMode="mosaic" \
    --perm.rename=false \
    --perm.execute=false \
    --perm.delete=false

sudo systemctl start filebrowser
```

**Note:** `config set` defaults only apply to NEW users. Update existing users individually with `filebrowser users update`.

## Step 7: Update Agent TOOLS.md

Add FileBrowser to the agent's TOOLS.md so it knows about the tool and can share direct URLs:

```markdown
### FileBrowser (Workspace)
- **URL:** https://subdomain.example.com/filebrowser
- **Credential:** `~/.openclaw/credentials/filebrowser.json`
- **Service:** `sudo systemctl status filebrowser`

#### Direct File URLs
Share direct links to files when team members ask to see work:
- **Pattern:** `https://subdomain.example.com/filebrowser/files/{path}`
- After creating/updating files, include the direct URL in messages.
```

## Sharing Files

Direct URL pattern: `https://{host}/{base_url}/files/{relative_path}`

Examples:
- Folder: `https://workspace.example.com/filebrowser/files/spaces/brand-a/`
- File: `https://workspace.example.com/filebrowser/files/spaces/brand-a/research/INDEX.md`

Markdown, images, PDFs, and text files render inline in FileBrowser. Users click, read, done.

When the agent creates or updates a file that team members should see, include the direct URL in the message (Slack, Discord, etc.): *"Research complete — view the personas here: [URL]"*

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| "000 No connection" in folder view | FileBrowser calculating large folder sizes | Cosmetic — files still accessible |
| Database locked / timeout on CLI | Service is running and holds the lock | Stop service → run CLI command → start service |
| Login page not showing | Cloudflare Access redirect | Verify email first, then login |
| `baseURL` not working | Config not set or service not restarted | Stop → `config set --baseURL` → start |
| Quantum binary panics | Missing embedded frontend | Use original FileBrowser, not Quantum fork |
| Team renamed a file, agent broke | Rename permission was enabled | Disable rename: `users update <user> --perm.rename=false` |

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

- **Use original FileBrowser, not Quantum.** Quantum fork (`gtsteffaniak/filebrowser`) has better features (OIDC, search) but the standalone binary panics without Docker because it doesn't embed the frontend. Original binary is fully self-contained.
- **`config set` defaults only affect new users.** Existing users must be updated individually with `users update`. This is not obvious and causes confusion when settings "don't apply."
- **Database locks when service is running.** All CLI operations (`users add`, `users update`, `config set`) require stopping the service first. The database is SQLite (BoltDB) and doesn't support concurrent access.
- **`viewMode` accepts only "list" or "mosaic" via CLI.** The web UI shows "mosaic gallery" as an option but the CLI rejects it. Use "mosaic" in CLI commands.
- **Rename permission breaks agent references.** Agents reference files by path in roadmaps, indexes, and skills. A user renaming `INDEX.md` to `index.md` silently breaks references. Always disable rename for non-admin users.
- **Cloudflare Zero Trust requires a separate API token.** The standard Cloudflare API token (for DNS, Pages) does NOT include Zero Trust permissions. Ask the human to create a dedicated token with "Access: Apps and Policies - Edit" permission at the START of the Cloudflare Access setup — not after walking them through 15 minutes of dashboard clicking.
- **Cloudflare free Zero Trust plan requires a payment method.** The plan is $0 but Cloudflare still requires a card. Warn the human upfront.
- **FileBrowser has no per-folder permissions.** Permissions are per-user. Within their scope, all permissions apply uniformly. The "Rules" system can block paths but can't make them read-only. Use scope to control visibility, not granular folder access.
- **Self-signed certs work with Cloudflare Full mode.** No need for Let's Encrypt if using Cloudflare proxy. Set SSL mode to "Full" (not "Full Strict").
- **fail2ban works with journald backend.** FileBrowser logs failed logins to journald (not a file). Use `backend = systemd` and `journalmatch = _SYSTEMD_UNIT=filebrowser.service` in the jail config.
- **FileBrowser runs as the agent user.** This means file edits via FileBrowser are indistinguishable from agent edits in git. Both show as the same user. Not a problem in practice — team edits go to `/spaces` which the agent rarely force-resets.

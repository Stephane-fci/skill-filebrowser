# CONTEXT.md — FileBrowser (John)

Agent-specific FileBrowser configuration.

---

## This Agent

**URL:** https://studio.sfrance.co/filebrowser
**Direct file link:** `https://studio.sfrance.co/filebrowser/files/{path}`
**Port:** 8085
**Service:** `sudo systemctl status filebrowser`
**Database:** `/etc/filebrowser/filebrowser.db`
**Workspace root:** `/root/clawd`
**Credentials:** `~/.openclaw/credentials/filebrowser.json`

**Users:**

Passwords live only in `~/.openclaw/credentials/filebrowser.json`. Do not store or repeat FileBrowser passwords in workspace files.

| User | Scope | Role |
|------|-------|------|
| stephane | `/` | safe daily account: view, download, upload/create, edit/modify, share; no admin, execute, rename, or delete |
| stephane-admin | `/` | break-glass admin for intentional structural changes; execute disabled |

**Cloudflare Access:** `stephane.franceschini@gmail.com`

---

## Sensitive Auth Profiles Viewer

- **URL:** `https://studio.sfrance.co/filebrowser-auth/`
- **Direct auth profile file:** `https://studio.sfrance.co/filebrowser-auth/files/auth-profiles.json`
- **Service:** `filebrowser-auth.service`
- **Port:** `8086` on `127.0.0.1`
- **Database:** `/etc/filebrowser-auth/filebrowser.db`
- **Root:** `/root/.openclaw/agents/main/agent`
- **User:** existing `stephane` FileBrowser login only, imported by hash; permissions reduced to download-only/read-only.
- **Purpose:** temporary/direct inspection of John's live auth-profile files by Stephane. Do not add other users or broaden root without explicit approval.

## Mini-John Workspace Viewer

- **URL:** `https://studio.sfrance.co/filebrowser/mini-john/`
- **Direct files root:** `https://studio.sfrance.co/filebrowser/mini-john/files/`
- **Service:** `filebrowser-mini-john.service`
- **Port:** `8087` on `127.0.0.1`
- **Database:** `/etc/filebrowser-mini-john/filebrowser.db`
- **Root:** `/root/clawd/projects/mini-john-agent/agent-workspace`
- **Users:** reuses the existing John FileBrowser `stephane` and `stephane-admin` credentials from `~/.openclaw/credentials/filebrowser.json`; do not print passwords.
- **Purpose:** direct browsing/editing of MJ's actual boot workspace without navigating through `/projects/mini-john-agent/agent-workspace` in John's main FileBrowser.

## Fleet Overview

| Agent | URL | Status |
|-------|-----|--------|
| **John** | `studio.sfrance.co/filebrowser` | ✅ Live |
| **Caesar** | `lifely.sfrance.co/filebrowser` | ✅ Live |
| **Jess** | `judes.sfrance.co/jess/filebrowser` | ✅ Live |
| **Lina** | `judes.sfrance.co/lina/filebrowser` | ✅ Live |
| **Francesca** | `sally.sfrance.co/filebrowser` | ✅ Live |
| **Sentinelle** | `sentinelle.sfrance.co/filebrowser` | ✅ Live |
| **Cornelia** | `vps.lifely.network/lifely-cc-agent/cornelia-workspace/filebrowser/` | ✅ Canonical; old `cornelia.lifely.network/filebrowser` and `cornelia.sfrance.co/filebrowser` still exist |
| **Maurice** | `maurice.sfrance.co/filebrowser` | ✅ Live |

Most instances use: Cloudflare Access (email wall) → FileBrowser login → fail2ban.
**Sentinelle exception:** direct FileBrowser login only, no Cloudflare Access, plus fail2ban.


## Cornelia VPS canonical FileBrowser routes

- Cornelia workspace: `https://vps.lifely.network/lifely-cc-agent/cornelia-workspace/filebrowser/` rooted at `/home/cornelia/clawd`, service `filebrowser-cornelia-workspace.service`, safe editable permissions.
- PO Allocation source: `https://vps.lifely.network/lifely-cc-agent/po-allocation/filebrowser/` rooted at `/opt/lifely-po-allocation/source/apps/lifely-po-allocation`, service `filebrowser-po-allocation.service`, read-only permissions.
- Route credential note on Cornelia: `/home/cornelia/.openclaw/credentials/filebrowser-vps-routes.json`.

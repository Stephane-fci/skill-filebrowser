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

## Fleet Overview

| Agent | URL | Status |
|-------|-----|--------|
| **John** | `studio.sfrance.co/filebrowser` | ✅ Live |
| **Caesar** | `lifely.sfrance.co/filebrowser` | ✅ Live |
| **Jess** | `judes.sfrance.co/jess/filebrowser` | ✅ Live |
| **Lina** | `judes.sfrance.co/lina/filebrowser` | ✅ Live |
| **Francesca** | `sally.sfrance.co/filebrowser` | ✅ Live |
| **Sentinelle** | `sentinelle.sfrance.co/filebrowser` | ✅ Live |
| **Cornelia** | `cornelia.sfrance.co/filebrowser` | ✅ Live |

Most instances use: Cloudflare Access (email wall) → FileBrowser login → fail2ban.
**Sentinelle exception:** direct FileBrowser login only, no Cloudflare Access, plus fail2ban.

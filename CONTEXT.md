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

| User | Password | Scope | Role |
|------|----------|-------|------|
| stephane | `dBwE6WIoaxFFCmJ8qNTk` | `/` | admin (full access) |

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

All instances share the same security stack: Cloudflare Access (email wall) → FileBrowser login → fail2ban.

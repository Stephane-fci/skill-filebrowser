# LEARNINGS.md — FileBrowser

Append new learnings below with today's date.

---

## 2026-04-10 — OpenClaw workspace can be the real root
- On Sentinelle, the correct FileBrowser root was `/home/sentinelle/.openclaw/workspace`, not `~/clawd`.
- Reason: the live bootstrap files, data, and skills were present in the OpenClaw workspace path, and that is what the running agent actually reads.
- Practical rule: when setting up FileBrowser for an OpenClaw agent, verify the active workspace path before assuming `~/clawd` is the right root.

## 2026-04-10 — Nginx backups inside sites-enabled trigger duplicate server warnings
- Backing up an Nginx site file inside `/etc/nginx/sites-enabled/` caused `conflicting server name` warnings during `nginx -t`.
- Keep backups outside `sites-enabled`, or remove them before reload.

## 2026-04-21 — Direct links must be relative to the FileBrowser root, not the absolute workspace path
- A broken shared link to `system-experimentation` exposed a simple but important rule: John's FileBrowser is rooted at `/root/clawd`, so the direct URL path must start at `skills/...`, not `root/clawd/skills/...`.
- Practical rule: when sharing a FileBrowser link, convert the filesystem path into a path relative to the configured FileBrowser root before building the URL.

## 2026-04-26 — Rename/delete permissions can move canonical workspace folders

- John's `projects/` folder was accidentally moved to `resources/projects/` through FileBrowser at `2026-04-25 15:04:23 UTC` via `PATCH /api/resources/projects/?action=rename&destination=/resources/projects`.
- FileBrowser's rename permission can move entire top-level folders, including canonical workspace folders. This bypasses `WORKSPACE.md` because it happens through the browser UI, not through agent reasoning.
- Daily human accounts should not have `rename`, `delete`, `execute`, or admin permissions. Keep a separate break-glass admin account for intentional structural changes only.
- For agent workspaces, protect canonical folders (`projects`, `spaces`, `skills`, `memory`, root boot files) with permissions or operational rules. If FileBrowser cannot do path-specific read-only protection, prefer safe daily accounts over full admin for normal browsing/uploading.

## 2026-04-26 — Credential files can drift from live FileBrowser DB state

- During fleet hardening, Caesar's credential file described the `team` account as scoped to `/spaces`, but the live FileBrowser DB still had scope `/`.
- Treat credential files as documentation plus secret storage, not runtime truth. Verify live DB state with `filebrowser users ls --database ...` before claiming permissions/scopes.
- When hardening, update both the DB and the credential description so future agents do not trust stale access notes.

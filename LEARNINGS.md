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

## 2026-05-16 — Blank FileBrowser UI can be stale cached SPA assets
- John's FileBrowser showed as a blank white page for Stephane while server-side checks and fresh Puppeteer sessions worked.
- Root cause was likely stale/corrupt cached FileBrowser SPA assets: FileBrowser served static JS/CSS with `Cache-Control: public, max-age=86400`, so a browser could keep a bad app shell for a day.
- Fix applied on John: in `/etc/nginx/sites-available/ugc-studio`, the `/filebrowser/` location now hides upstream `Cache-Control`, sends `no-store, no-cache, must-revalidate`, strips upstream compression for HTML, and `sub_filter`s `.js`/`.css` asset URLs with `?v=20260516-filebrowser-fix` to force a fresh frontend load.
- Verification: public `GET https://studio.sfrance.co/filebrowser/` returns cache-busted static asset URLs; Puppeteer can load login, log in as daily user, and browse `/projects/lifely-post-purchase-experience/media/` from the public URL.

## 2026-05-16 — John's FileBrowser moved to `/john-files` after persistent blank SPA
- The first cache-busting attempt on `/filebrowser/` still left Stephane seeing the blue-spinner blank screen on multiple devices.
- Permanent operational fix: moved John's FileBrowser base URL from `/filebrowser` to `/john-files`, redirected old `/filebrowser` paths to `/john-files/`, and kept no-store/cache-busted JS/CSS on the new route.
- Backups made before change: `/etc/nginx/sites-available/ugc-studio.bak-john-files-<timestamp>` and `/etc/filebrowser/filebrowser.db.bak-john-files-<timestamp>`.
- Verified with public Puppeteer login: `https://studio.sfrance.co/john-files/files/projects/lifely-post-purchase-experience/media/` loads and lists files.
- Update shared links for John to use `https://studio.sfrance.co/john-files/files/{path}`. Old `/filebrowser` should redirect, but new links should use `/john-files` directly.

## 2026-05-16 — Real FileBrowser failure was disk-full nginx temp truncation, not route/baseURL
- The persistent FileBrowser blue-spinner issue was ultimately caused by `/` being 100% full. Nginx logged `pwritev() /var/lib/nginx/proxy/... failed (28: No space left on device)` while streaming FileBrowser JS assets, and browsers reported `ERR_INCOMPLETE_CHUNKED_ENCODING`.
- Fix sequence: free safe cache/temp space, then set FileBrowser Nginx route with `proxy_buffering off`, `proxy_request_buffering off`, and `proxy_max_temp_file_size 0` so FileBrowser assets do not depend on nginx disk temp files.
- Temporary route moves can hide symptoms but do not solve this class of issue. Always check `df -h /` and nginx error logs when browser shows a blank FileBrowser spinner with incomplete chunk errors.

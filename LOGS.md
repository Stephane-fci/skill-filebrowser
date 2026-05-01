# LOGS.md — FileBrowser

---
## 2026-04-09 — Caesar FileBrowser Access
- Added `chloe.Lin@lifely.com.au` to the Cloudflare Access reusable allow policy for Caesar FileBrowser.
- Used Cloudflare Zero Trust API `PUT /accounts/{account_id}/access/policies/{policy_id}` against policy `5f593921-c742-4ffc-86c5-2e5bc776361d`.
- Result: success=true, include_count=13.

## 2026-04-10 — Caesar FileBrowser Access
- Added `yunkai@lifely.com.au` to the Cloudflare Access reusable allow policy for Caesar FileBrowser.
- Used Cloudflare Zero Trust API `PUT /accounts/{account_id}/access/policies/{policy_id}` against policy `5f593921-c742-4ffc-86c5-2e5bc776361d`.
- Result: success=true, include_count=14.

## 2026-04-10 — Caesar FileBrowser Access
- Added `vivi.sheh@lifely.com.au` to the Cloudflare Access reusable allow policy for Caesar FileBrowser.
- First update request appears to have succeeded; a clean retry immediately afterward reported the email was already present.
- Policy target remained `5f593921-c742-4ffc-86c5-2e5bc776361d`.

## 2026-04-10 — Sentinelle FileBrowser Setup
- Installed original FileBrowser v2.63.1 on Valmy.
- Rooted it at `/home/sentinelle/.openclaw/workspace`, not `~/clawd`, because Sentinelle’s live bootstrap/data/skills are in the OpenClaw workspace path.
- Exposed it at `https://sentinelle.sfrance.co/filebrowser` through the existing Nginx server block.
- Created admin user `stephane`, disabled execute/delete/rename, and stored credentials on Valmy at `/home/sentinelle/.openclaw/credentials/filebrowser.json`.
- Added fail2ban protection, verified the login API returned HTTP 200, and updated Sentinelle’s `TOOLS.md` with the FileBrowser URL.

## 2026-04-20 — Sentinelle FileBrowser password reset request
- Trigger: Stephane asked to replace the Sentinelle FileBrowser password with `[redacted-filebrowser-password]`.
- Actions: stopped the FileBrowser service on Valmy, ran `filebrowser users update stephane --password ...` against `/etc/filebrowser/filebrowser.db`, and restarted the service.
- Outcome: password reset command applied cleanly. Curl-based login verification on the public endpoint returned HTTP 403 even for a temporary fresh test user, which suggests the verification path itself is not trustworthy here; the CLI update path is the source-of-truth result.

## 2026-04-20 — Created simple Sentinelle FileBrowser collaborator accounts
- Trigger: Stephane asked for simpler FileBrowser credentials for Dorian and Nicolas, with the same easy password on both accounts.
- Actions: created or updated `dorian` and `nicolas` in `/etc/filebrowser/filebrowser.db`, set scope `/`, disabled admin/execute/delete/rename, and set the shared password to `[redacted-filebrowser-password]` because FileBrowser enforces a minimum password length of 12.
- Outcome: both collaborator accounts now exist and are listed by the FileBrowser CLI on Valmy.

## 2026-04-17 — Caesar live AGENTS.md snippet lookup
- Trigger: Stephane asked to see the exact part of Caesar's live `AGENTS.md` that resolves the current sender against the people database.
- Actions: Read the FileBrowser skill context, fetched the live `AGENTS.md` snippet from Caesar, and confirmed the related enforcement rule also lives in `RULES.md`.
- Outcome: Returned the exact boot snippet plus the rule that makes Caesar consult the resolver before gated tools.

## 2026-04-18 — Cin7 mirror database status link
- Trigger: Stephane asked to see the database already populated and wanted a link.
- Actions: Read the FileBrowser skill context, created a human-readable status file in the workspace summarizing the current Cin7 mirror population state, and prepared the direct FileBrowser URL.
- Outcome: Shared a direct link to the current database status report instead of pretending a full DB browser UI already exists.

## 2026-04-18 — Cin7 mirror table export view
- Trigger: Stephane asked to see the actual populated database, not just a status note.
- Actions: Exported the live populated Cin7 mirror tables from Caesar into CSV snapshots under the workspace and created an `index.html` page linking the exported tables.
- Outcome: Prepared a browsable FileBrowser view of the actual synced table rows for the stock layer.

## 2026-04-21 — Broken direct link for system-experimentation skill
- Trigger: Stephane showed that the FileBrowser link to `system-experimentation` returned "This location can't be reached."
- Actions: Re-read the FileBrowser skill and local context, confirmed John's FileBrowser root is `/root/clawd` and the user scope is `/`, then checked the shared URL and found it incorrectly used the absolute workspace path.
- Outcome: Confirmed the correct direct links must use paths relative to the FileBrowser root, for example `skills/system-experimentation/` instead of `root/clawd/skills/system-experimentation/`.


## 2026-04-25 — Judes retainer positioning draft link
- Trigger: Stephane asked for a polished Markdown draft and a FileBrowser link.
- Actions: Read the FileBrowser skill context, created `resources/notes/2026-04-25-judes-retainer-positioning-message.md`, verified the file, and prepared a direct link relative to John's FileBrowser root.
- Outcome: Shared the direct FileBrowser link to the draft.

## 2026-04-26 — John FileBrowser hardening after projects-folder move
- Root cause: FileBrowser moved `/projects/` to `/resources/projects/` through an authenticated rename/move request.
- Actions: stopped FileBrowser briefly for DB-safe user updates, created/verified a separate `stephane-admin` break-glass account, changed the normal `stephane` account to non-admin with execute/rename/delete disabled, and restarted the service.
- Credential hygiene: removed plaintext FileBrowser passwords from `platform-filebrowser/CONTEXT.md` and redacted legacy plaintext copies found in workspace notes/logs/memory. Passwords live only in `~/.openclaw/credentials/filebrowser.json`.
- Outcome: daily browsing/upload/editing can continue, but the normal account can no longer move or delete top-level workspace folders.

## 2026-04-26 — Fleet FileBrowser hardening after John workspace incident
- Trigger: John's `/projects/` folder move showed that FileBrowser rename/admin access can move canonical workspace folders outside agent guardrails.
- Actions: audited Caesar, Jess, Lina, and Francesca FileBrowser DB users; changed daily human accounts to non-admin with execute/rename/delete disabled; created break-glass admin accounts with execute disabled; stored generated break-glass passwords only in each agent's `.openclaw/credentials/filebrowser.json`.
- Caesar detail: corrected `team` runtime scope to `/spaces` to match the credential file and reduce access surface.
- Outcome: active fleet daily accounts can browse/upload/edit/share/download but can no longer rename/delete top-level workspace folders.

## 2026-04-28 — Maurice FileBrowser public protected setup
- Trigger: Stephane said to continue Maurice production-gate work after GitHub backup.
- Actions: Installed Nginx on Maurice, created self-signed cert for `maurice.sfrance.co`, proxied `/filebrowser` to local FileBrowser on `127.0.0.1:8085`, created proxied Cloudflare DNS A record, created Cloudflare Access app `Maurice FileBrowser` with Stephane-only policy, and restricted UFW `80/443` to Cloudflare IP ranges only.
- Outcome: `https://maurice.sfrance.co/filebrowser/` redirects to Cloudflare Access; root returns 404; direct IP access from John timed out. Maurice TOOLS.md updated and pushed to `lifely-abundance/maurice-brain` commit `ef30e46`.

## 2026-04-29 — Cornelia FileBrowser public protected setup
- Trigger: Stephane said “let's go” for Cornelia deployment Phase 8 operational infrastructure.
- Actions: Installed original FileBrowser v2.63.2 on `lifely-cc-agent`, rooted it at `/home/cornelia/clawd`, created safe daily `stephane` and break-glass `stephane-admin` users with passwords stored only in `/home/cornelia/.openclaw/credentials/filebrowser.json`, proxied `/filebrowser` through Nginx at `cornelia.sfrance.co`, created proxied Cloudflare DNS and a `Cornelia FileBrowser` Access app with Stephane-only policy, enabled the FileBrowser fail2ban jail, and restricted UFW HTTP/HTTPS to Cloudflare IP ranges.
- Outcome: `https://cornelia.sfrance.co/filebrowser/` redirects to Cloudflare Access, local FileBrowser login returns HTTP 200, root returns 404, and direct IP access to ports 80/443 times out. Cornelia `TOOLS.md` was updated with the URL and credential path.

## 2026-04-29 — Maurice FileBrowser password aligned with Caesar
- Trigger: Stephane asked to set Maurice's FileBrowser password to the same daily `stephane` password used for Caesar FileBrowser.
- Actions: Read Caesar's stored FileBrowser credential from the secure Lifely VPS credential file without printing it, updated Maurice's `stephane` FileBrowser user via the FileBrowser CLI, preserved safe daily-user permissions, updated Maurice's secure credential JSON, and verified local login on Maurice returned HTTP 200.
- Outcome: Maurice FileBrowser daily `stephane` login now uses the same stored password as Caesar. No password was written to workspace docs or shown in chat/logs.

## 2026-05-01 — Cornelia FileBrowser password aligned with John
- Trigger: Stephane asked to make Cornelia FileBrowser daily user `stephane` use the same password as John's FileBrowser daily user.
- Actions: Read John's secure credential file without printing the password, updated Cornelia's FileBrowser DB user, preserved daily safe permissions, updated Cornelia's secure credential JSON, restarted FileBrowser, and verified local login HTTP `200`.
- Outcome: Cornelia `stephane` FileBrowser password now matches John's daily FileBrowser password. No secret was printed or stored in workspace docs.

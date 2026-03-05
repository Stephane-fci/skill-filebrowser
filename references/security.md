# Security Reference

## Known Vulnerabilities

| CVE | Severity | Impact | Status |
|-----|----------|--------|--------|
| CVE-2021-46398 | Critical | CSRF → RCE | Fixed in v2.18.0+ |
| CVE-2023-39612 | High | XSS → admin takeover | Patch status unclear — mitigate with Cloudflare Access |

## Built-in Security Limitations

FileBrowser has **no built-in brute-force protection**. Without external protection, attackers can attempt unlimited password guesses. Mitigation: fail2ban + Cloudflare Access.

FileBrowser has **no 2FA**. Mitigation: Cloudflare Access provides email-based verification as a second factor.

The **execute permission** allows running arbitrary shell commands. **Always disable globally** unless you have a specific, controlled use case.

## Recommended Security Stack (Defense in Depth)

1. **Cloudflare Access** (outermost) — Email verification before seeing the login page. Blocks all unauthorized traffic.
2. **FileBrowser login** (middle) — Username + password (min 12 chars enforced).
3. **fail2ban** (innermost) — Blocks IPs after repeated failed logins.

## Permission Model

FileBrowser permissions are **per-user, not per-folder**. Within their scope, all permissions apply uniformly.

| Permission | Recommended for Admin | Recommended for Collaborator | Recommended for Viewer |
|------------|----------------------|------------------------------|----------------------|
| admin | ✅ | ❌ | ❌ |
| execute | ❌ (disable globally) | ❌ | ❌ |
| create | ✅ | ✅ | ❌ |
| rename | ✅ | ❌ (breaks agent file references) | ❌ |
| modify | ✅ | ✅ | ❌ |
| delete | ✅ | ❌ (prevention > recovery) | ❌ |
| share | ✅ | ✅ | ❌ |
| download | ✅ | ✅ | ✅ |

## Scope Strategy

- **Admin** → scope `/` — full workspace access
- **Collaborator** → scope `/` with `hideDotfiles=true` — sees workspace files, agent credentials hidden in dotfiles
- **Restricted user** → scope set to a subfolder (e.g. `/shared`, `/output`) — only sees that folder
- **Viewer** → scope `/` with read-only permissions — sees everything, changes nothing

**Recommendation:** Start with scope `/` + `hideDotfiles=true` for trusted users. Restricting scope causes URL path mismatches (see SKILL.md "Sharing Files"). Only restrict scope for untrusted or external users.

Agent credentials typically live in dotfiles (e.g. `.openclaw/credentials/`) which are hidden when `hideDotfiles=true`.

## Cloudflare Access Setup via API

Requires a Cloudflare API token with **Account → Access: Apps and Policies → Edit** permission.

```bash
# Create application
curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/access/apps" \
  -H "Authorization: Bearer $ZT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "FileBrowser",
    "domain": "subdomain.example.com/filebrowser",
    "type": "self_hosted",
    "session_duration": "24h"
  }'

# Create policy
curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/access/apps/$APP_ID/policies" \
  -H "Authorization: Bearer $ZT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Allowed Users",
    "decision": "allow",
    "include": [
      {"email": {"email": "user@example.com"}}
    ]
  }'
```

If no Zero Trust API token exists, guide the human through the dashboard:
1. https://one.dash.cloudflare.com → Zero Trust (may require free plan activation + payment method)
2. Access → Applications → Add Application → Self-hosted
3. Set subdomain, domain, path
4. Create Allow policy with team email addresses

**Ask the human to create a Zero Trust API token early** so you can manage Access programmatically:
- Profile → API Tokens → Create Token → Custom → Account → Access: Apps and Policies → Edit

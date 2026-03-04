#!/bin/bash
# fail2ban setup for FileBrowser
# Run as root or with sudo
# Usage: sudo bash setup-fail2ban.sh [max_retry] [ban_time_seconds]

set -euo pipefail

MAX_RETRY="${1:-5}"
BAN_TIME="${2:-3600}"

echo "=== FileBrowser fail2ban Setup ==="

# Check fail2ban is installed
if ! command -v fail2ban-client &>/dev/null; then
    echo "Installing fail2ban..."
    apt-get update -qq && apt-get install -y -qq fail2ban
fi

# Create filter
cat > /etc/fail2ban/filter.d/filebrowser.conf << 'FILTEREOF'
[Definition]
failregex = /api/login: 403 <HOST>
ignoreregex =
journalmatch = _SYSTEMD_UNIT=filebrowser.service
FILTEREOF

# Create jail
cat > /etc/fail2ban/jail.d/filebrowser.conf << JAILEOF
[filebrowser]
enabled = true
filter = filebrowser
backend = systemd
maxretry = $MAX_RETRY
findtime = 600
bantime = $BAN_TIME
action = %(action_)s
JAILEOF

# Restart fail2ban
systemctl restart fail2ban
sleep 2

# Verify
if fail2ban-client status filebrowser &>/dev/null; then
    echo "✅ fail2ban jail 'filebrowser' is active"
    echo "   Max retries: $MAX_RETRY | Ban time: ${BAN_TIME}s | Find time: 600s"
    fail2ban-client status filebrowser
else
    echo "❌ Failed to activate jail"
    exit 1
fi

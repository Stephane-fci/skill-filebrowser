#!/bin/bash
# FileBrowser Installation Script
# Run as root or with sudo on a VPS
# Usage: sudo bash install.sh <workspace_path> <service_user> <port> [base_url]
#
# Example: sudo bash install.sh /home/myagent/workspace myagent 8085 /filebrowser

set -euo pipefail

WORKSPACE_PATH="${1:?Usage: install.sh <workspace_path> <service_user> <port> [base_url]}"
SERVICE_USER="${2:?Usage: install.sh <workspace_path> <service_user> <port> [base_url]}"
PORT="${3:?Usage: install.sh <workspace_path> <service_user> <port> [base_url]}"
BASE_URL="${4:-}"

echo "=== FileBrowser Installation ==="
echo "Workspace: $WORKSPACE_PATH"
echo "User: $SERVICE_USER"
echo "Port: $PORT"
echo "Base URL: ${BASE_URL:-/}"

# Check workspace exists
if [ ! -d "$WORKSPACE_PATH" ]; then
    echo "❌ Workspace path does not exist: $WORKSPACE_PATH"
    exit 1
fi

# Check user exists
if ! id "$SERVICE_USER" &>/dev/null; then
    echo "❌ User does not exist: $SERVICE_USER"
    exit 1
fi

# Download FileBrowser (original, self-contained binary with embedded frontend)
echo ""
echo "📦 Downloading FileBrowser..."
if [ -f /usr/local/bin/filebrowser ]; then
    echo "  Already installed at /usr/local/bin/filebrowser"
    /usr/local/bin/filebrowser version 2>/dev/null || true
else
    curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
    echo "  ✅ Installed: $(/usr/local/bin/filebrowser version 2>/dev/null)"
fi

# Create database directory
echo ""
echo "🗃️  Setting up database..."
mkdir -p /etc/filebrowser
DB_PATH="/etc/filebrowser/filebrowser.db"

if [ -f "$DB_PATH" ]; then
    echo "  Database already exists at $DB_PATH"
else
    # Initialize config
    /usr/local/bin/filebrowser config init --database "$DB_PATH" 2>/dev/null

    # Set server config
    /usr/local/bin/filebrowser config set --database "$DB_PATH" \
        --address 127.0.0.1 \
        --port "$PORT" \
        --root "$WORKSPACE_PATH" \
        --auth.method=json \
        --signup=false \
        --perm.execute=false \
        --perm.delete=false \
        --perm.rename=false \
        --branding.name "Workspace" \
        --hideDotfiles=true \
        --sorting.asc=true \
        --viewMode="mosaic" 2>/dev/null

    # Set base URL if provided
    if [ -n "$BASE_URL" ]; then
        /usr/local/bin/filebrowser config set --database "$DB_PATH" \
            --baseURL "$BASE_URL" 2>/dev/null
    fi

    # Set token expiration to 24h
    /usr/local/bin/filebrowser config set --database "$DB_PATH" \
        --tokenExpirationTime "24h" 2>/dev/null

    echo "  ✅ Database created and configured"
fi

# Set ownership
chown "$SERVICE_USER:$SERVICE_USER" "$DB_PATH"

# Create systemd service
echo ""
echo "⚙️  Creating systemd service..."
cat > /etc/systemd/system/filebrowser.service << SERVICEEOF
[Unit]
Description=FileBrowser - Workspace File Manager
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
ExecStart=/usr/local/bin/filebrowser --database $DB_PATH
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl daemon-reload
systemctl enable filebrowser
echo "  ✅ Service created and enabled"

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Next steps:"
echo "  1. Create users:  sudo /usr/local/bin/filebrowser users add <username> <password> --database $DB_PATH"
echo "  2. Start service: sudo systemctl start filebrowser"
echo "  3. Set up Nginx reverse proxy (see SKILL.md)"
echo "  4. Set up DNS + SSL (see SKILL.md)"
echo ""
echo "FileBrowser will listen on 127.0.0.1:$PORT (localhost only — needs Nginx to expose)"

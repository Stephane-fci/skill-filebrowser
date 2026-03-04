# Nginx Configuration Templates

## Main Config (with base URL path)

Use this when FileBrowser lives at a subpath like `example.com/filebrowser`.

```nginx
server {
    listen 80;
    listen 443 ssl;
    server_name {SUBDOMAIN}.{DOMAIN};

    ssl_certificate /etc/nginx/ssl/filebrowser.crt;
    ssl_certificate_key /etc/nginx/ssl/filebrowser.key;

    client_max_body_size 100M;

    # FileBrowser at /{BASE_URL}
    location /{BASE_URL}/ {
        proxy_pass http://127.0.0.1:{PORT};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Root — return 404 or redirect
    location / {
        return 404;
    }
}
```

## Root Config (no base URL)

Use this when FileBrowser is the only thing on the subdomain (e.g. `files.example.com`).

```nginx
server {
    listen 80;
    listen 443 ssl;
    server_name {SUBDOMAIN}.{DOMAIN};

    ssl_certificate /etc/nginx/ssl/filebrowser.crt;
    ssl_certificate_key /etc/nginx/ssl/filebrowser.key;

    client_max_body_size 100M;

    location / {
        proxy_pass http://127.0.0.1:{PORT};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## SSL Certificate (Self-signed for Cloudflare)

When using Cloudflare proxy with SSL mode "Full", a self-signed cert is sufficient:

```bash
sudo mkdir -p /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/filebrowser.key \
    -out /etc/nginx/ssl/filebrowser.crt \
    -subj "/CN={SUBDOMAIN}.{DOMAIN}"
```

## Enable and Test

```bash
sudo ln -sf /etc/nginx/sites-available/{CONFIG_NAME} /etc/nginx/sites-enabled/{CONFIG_NAME}
sudo nginx -t
sudo nginx -s reload
```

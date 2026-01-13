#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Uso: ./install-nginx.sh <dominio> <email>"
    exit 1
fi

DOMAIN="$1"
EMAIL_TO_CERBOT="$2"
XMLRPC_PORT="8069"
GEVENT_PORT="8072"

CONF_FILE="/etc/nginx/sites-available/$DOMAIN"
ENABLED_FILE="/etc/nginx/sites-enabled/$DOMAIN"

echo "Instalando Certbot..."
apt update
apt install certbot python3-certbot-nginx -y

systemctl stop nginx
echo "Generando certificados SSL para $DOMAIN..."

certbot certonly --standalone -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos --email "$EMAIL_TO_CERBOT"

if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "Error: Los certificados no se generaron. Revisa tu DNS."
    exit 1
fi

echo "Creando configuración completa de Odoo..."

cat >"$CONF_FILE" <<EOL
upstream odoo_chat {
    server 127.0.0.1:$GEVENT_PORT;
}

map \$http_upgrade \$connection_upgrade {
  default upgrade;
  ''      close;
}

map \$sent_http_content_type \$content_type_csp {
    default "";
    ~image/ "default-src 'none'";
}

server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN www.$DOMAIN;

    client_max_body_size 0;

    # Rutas de certificados (Certbot ya los creó arriba)
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers HIGH:!aNULL:!MD5;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
    add_header Content-Security-Policy \$content_type_csp;

    proxy_cookie_flags session_id samesite=lax secure;

    location /websocket {
        proxy_pass http://odoo_chat;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Real-IP \$remote_addr;

        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
        proxy_cookie_flags session_id samesite=lax secure;

        proxy_read_timeout 720s;
        proxy_connect_timeout 720s;
        proxy_send_timeout 720s;
    }

    location /longpolling/ {
        proxy_pass http://odoo_chat;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_http_version 1.1;
        proxy_read_timeout 3600s;
    }

    location / {
        proxy_pass http://127.0.0.1:$XMLRPC_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

ln -sf "$CONF_FILE" "$ENABLED_FILE"
rm -f /etc/nginx/sites-enabled/default

nginx -t
if [ $? -eq 0 ]; then
    echo "Configuración válida. Iniciando Nginx..."
    systemctl start nginx
    systemctl enable certbot.timer
else
    echo "Error en la configuración de Nginx."
    exit 1
fi
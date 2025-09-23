#!/bin/bash

# This script adds a new Nginx configuration file to the specified directory.
# Usage: ./add-nginx-conf.sh <name_of_conf_file> <email_for_cerbot> <dev - opcional>
if [ -z "$1" ] || [ -z "$2" ]; then
	echo "Error: Debes proporcionar el nombre del archivo de configuración y el correo electrónico para Certbot."
	echo "Uso: ./add-nginx-conf.sh <name_of_conf_file> <email_for_cerbot> <dev - opcional>"
	exit 1
fi

XMLRPC_PORT="8069"
GEVENT_PORT="8072"

if [ -n "$3" ] && [ "$3" == "dev" ]; then
	XMLRPC_PORT="7069"
	GEVENT_PORT="7072"
	echo "Configurado para entorno de desarrollo: XMLRPC_PORT=$XMLRPC_PORT, GEVENT_PORT=$GEVENT_PORT"
fi

EMAIL_TO_CERBOT="$2"

# Script to install Nginx on Debian 11 (Bullseye)
SERVICE_NAME="nginx"
echo ""
echo "----------------------------------------------------------------------"
echo "Instalando Nginx..."

apt install nginx -y

echo "----------------------------------------------------------------------"
echo ""

echo "Servicio de inicio y habilitación de Nginx..."
systemctl start $SERVICE_NAME
systemctl enable $SERVICE_NAME
echo "La instalación de Nginx se completó y el servicio se inició."
echo ""

systemctl daemon-reload

if systemctl list-unit-files | grep -q "^$SERVICE_NAME"; then
	echo "El servicio '$SERVICE_NAME' existe."

	if systemctl is-active "$SERVICE_NAME"; then
		echo "El servicio '$SERVICE_NAME' ya está activo."
	else
		echo "Activando y habilitando el servicio '$SERVICE_NAME'..."
		systemctl enable --now "$SERVICE_NAME"
		echo "Servicio '$SERVICE_NAME' activado."
	fi
fi

echo ""
echo "----------------------------------------------------------------------"
echo "Agregando configuracion de nginx"

CONF_DIR="/etc/nginx/sites-available/"
CONF_FILE="$CONF_DIR/$1"
ENABLED_DIR="/etc/nginx/sites-enabled/"
ENABLED_FILE="$ENABLED_DIR/$1"

if [ -e "$CONF_FILE" ]; then
	echo "Error: El archivo de configuración '$1' ya existe en '$CONF_DIR'."
	exit 1
fi

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
    server_name $1 www.$1;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $1 www.$1;

    client_max_body_size 0;

    ssl_certificate /etc/letsencrypt/live/$1/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$1/privkey.pem;

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

# Verificar si se ha creado correctamente el archivo
if [ $? -eq 0 ]; then
	echo "Archivo de configuración '$CONF_FILE' creado con éxito."
else
	echo "Error al crear el archivo de configuración."
	exit 1
fi

# Crear un enlace simbólico en sites-enabled si no existe
if [ ! -e "$ENABLED_FILE" ]; then
	ln -s "$CONF_FILE" "$ENABLED_FILE"
	echo "Enlace simbólico creado en '$ENABLED_FILE'."
else
	echo "El enlace simbólico '$ENABLED_FILE' ya existe."
fi

# Verificar la sintaxis de Nginx
nginx -t
if [ $? -eq 0 ]; then
	echo "La configuración de Nginx es válida. Recargando Nginx..."
	systemctl reload nginx
else
	echo "Error en la configuración de Nginx. No se recargó el servicio."
	exit 1
fi

# Instalar Certbot y el plugin de Nginx para generar el certificado SSL
echo "----------------------------------------------------------------------"
echo "Instalando Certbot y plugin de Nginx..."

# Instalar Certbot
apt install certbot python3-certbot-nginx -y

# Generar el certificado SSL para el dominio
echo "Generando certificado SSL para $1..."
certbot --nginx -d $1 -d www.$1 --non-interactive --agree-tos --email $EMAIL_TO_CERBOT

# Verificar si el certificado fue generado exitosamente
if [ $? -eq 0 ]; then
	echo "Certificado SSL generado correctamente para $1."
else
	echo "Error al generar el certificado SSL. Revisa los detalles e intenta nuevamente."
	exit 1
fi

# Configurar renovación automática de certificados
echo "Configurando renovación automática del certificado..."
systemctl enable --now certbot.timer
echo "Renovación automática de certificados configurada."

echo ""
echo "----------------------------------------------------------------------"
echo "Configuración completada con éxito para Nginx y Certbot."

exit 0

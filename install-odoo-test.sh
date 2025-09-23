#!/bin/bash

# This script adds a new Nginx configuration file to the specified directory.
# Usage: ./install-odoo-test.sh <nombre de directorio> <version de odoo - opcional>

if [ -z "$1" ]; then
	echo "Error: Debes proporcionar el nombre del directorio."
	echo "Uso: ./install-odoo-test.sh <nombre de directorio> <version de odoo - opcional>"
	exit 1
fi

if [ -n "$2" ]; then
	ODOO_VERSION="$2"
	if ! [[ "$ODOO_VERSION" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
		echo "Error: La versión de Odoo '$ODOO_VERSION' no es válida."
		exit 1
	fi
fi

command -v git >/dev/null 2>&1 || {
	echo "Error: 'git' no está instalado."
	exit 1
}
command -v python3 >/dev/null 2>&1 || {
	echo "Error: 'python3' no está instalado."
	exit 1
}
command -v systemctl >/dev/null 2>&1 || {
	echo "Error: 'systemctl' no está disponible."
	exit 1
}

echo ""
echo "----------------------------------------------------------------------"
echo "Instalando Odoo..."

ODOO_DIR="/opt/$1"

if [ -d "$ODOO_DIR" ]; then
	echo "El directorio '$ODOO_DIR' ya existe coloca otro directorio para realizar pruebas."
	exit 1
else
	echo "Creando directorio -> $ODOO_DIR."
	mkdir "$ODOO_DIR"
fi

declare -a directories=(
	"$ODOO_DIR/extra-addons"
	"$ODOO_DIR/downloaded-addons"
	"$ODOO_DIR/conf"
	"$ODOO_DIR/log"
)

for dir in "${directories[@]}"; do
	if [ -d "$dir" ]; then
		echo "El directorio '$dir' ya existe."
	else
		echo "Creando directorio -> '$dir'."
		mkdir "$dir"
	fi
done

if [ -d "$ODOO_DIR/odoo" ]; then
	echo "El directorio '$ODOO_DIR/odoo' ya existe."
else
	echo "Creando directorio -> '$ODOO_DIR/odoo'."
	if [ -n "$2" ]; then
		git clone https://github.com/odoo/odoo.git -b $ODOO_VERSION --depth 1 $ODOO_DIR/odoo
	else
		git clone https://github.com/odoo/odoo.git --depth 1 $ODOO_DIR/odoo
	fi
fi

CONF_FILE="$ODOO_DIR/conf/odoo.conf"

# core
# (CPU cores * 2 + 1)
NUM_WORKERS="$(($(nproc) * 2))"

# RAM
RAM_GB=$(grep MemTotal /proc/meminfo | awk '{print int($2*1024)}')
ODOO_RAM=$(($RAM_GB * 75 / 100))
RAM_PER_WORKER=$(($ODOO_RAM / $NUM_WORKERS))
LIMIT_SOFT=$(($RAM_PER_WORKER * 80 / 100))
LIMIT_HARD=$(($RAM_PER_WORKER * 110 / 100))

# if [ -d "$CONF_FILE" ]; then
# 	echo "$CONF_FILE ya existe."
# else
# fi
cat >"$CONF_FILE" <<EOL
[options]
db_host = False
db_port = False
db_user = $1
db_password = False
xmlrpc_port = 7069
longpolling_port = False
gevent_port = 7072
limit_memory_hard = $LIMIT_HARD
limit_memory_soft = $LIMIT_SOFT
limit_request = 8192
limit_time_cpu = 600
limit_time_real = 1200
max_cron_threads = 2
workers = $NUM_WORKERS
data_dir = /opt/$1/data
logfile = /opt/$1/log/odoo-server.log
logrotate = True
proxy_mode = True
addons_path = /opt/$1/odoo/addons,/opt/$1/extra-addons,/opt/$1/downloaded-addons
EOL

# virtualenv
if [ -d "$ODOO_DIR/venv" ]; then
	echo "El directorio '$ODOO_DIR/venv' ya existe."
else
	echo "Creando entorno virtual -> $ODOO_DIR/venv."
	python3 -m venv $ODOO_DIR/venv
fi

SERVICE_CONF="/etc/systemd/system/$1-odoo-server.service"
cat >"$SERVICE_CONF" <<EOL
[Unit]
Description=$1 odoo server
After=postgresql.service

[Service]
Restart=on-failure
RestartSec=5s
Type=simple
User=$1
ExecStart=$ODOO_DIR/venv/bin/python3 $ODOO_DIR/odoo/odoo-bin --config $CONF_FILE

[Install]
WantedBy=multi-user.target
EOL

# add user
if id "$1" &>/dev/null; then
	echo "El usuario '$1' ya existe."
else
	useradd -m -d $ODOO_DIR -U -r -s /bin/bash $1
	echo "Usuario '$1' creado."
fi

# chown
chown -R $1:$1 $ODOO_DIR

# Servicio
SERVICE_NAME="$1-odoo-server.service"
systemctl daemon-reload

if systemctl is-active "$SERVICE_NAME" >/dev/null 2>&1; then
	echo "El servicio '$SERVICE_NAME' ya está activo."
else
	echo "Activando y habilitando el servicio '$SERVICE_NAME'..."
	systemctl enable --now "$SERVICE_NAME"
	echo "Servicio '$SERVICE_NAME' activado."
fi

# datos
echo "----------------------------------------------------------------------"
echo ""

echo "Usuario de Odoo -> $1"
cat /etc/passwd | grep $1

echo ""

echo "Archivo de servicio -> $SERVICE_CONF"
cat $SERVICE_CONF

echo ""

echo "Archivo de configuración -> $CONF_FILE"
cat $CONF_FILE

echo ""

echo "Versión de Odoo -> $($ODOO_DIR/venv/bin/python3 $ODOO_DIR/odoo/odoo-bin --version)"

echo ""
echo "----------------------------------------------------------------------"

exit 0

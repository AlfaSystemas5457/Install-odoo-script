#!/bin/bash

# This script adds a new PostgreSQL user and verifies its creation.
# Usage: install-postgreSQL.sh <user_postgreSQL>

if [ -z "$1" ]; then
	echo "Error: Debes proporcionar el nombre del usuario de PostgreSQL."
	echo "Uso: install-postgreSQL.sh <user_postgreSQL>"
	exit 1
fi

USER="$1"

echo ""
echo "----------------------------------------------------------------------"
echo "Instalando PostgreSQL..."
echo ""

apt install postgresql -y

if su - postgres -c "psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='$USER'\" | grep -q 1"; then
	echo "El usuario PostgreSQL '$USER' ha sido creado con éxito."
else
	echo "Creando el usuario PostgreSQL '$USER'..."
	su - postgres -c "createuser -s $USER"
	echo "Usuario '$USER' creado"
fi

echo ""
echo "----------------------------------------------------------------------"

exit 0

#!/bin/bash

echo ""
echo "----------------------------------------------------------------------"
echo "Instalando dependencias..."

apt-get update -y

command_check_and_install() {
	local command=$1
	local package=$2

	if [ command -v $command >/dev/null 2>&1 -ne 0 ]; then
		echo "El comando '$command' no está instalado. Instalando '$package'..."
		apt install -y $package
	else
		echo "El comando '$command' ya está instalado."
	fi
}

command_check_and_install "git" "git"
command_check_and_install "python3" "python3"
command_check_and_install "python3-venv" "python3-venv"
command_check_and_install "systemctl" "systemd"
command_check_and_install "curl" "curl"

# Verificación e instalación de dependencias adicionales para Odoo
command_check_and_install "python3-dev" "python3-dev"
command_check_and_install "python3-pip" "python3-pip"
command_check_and_install "build-essential" "build-essential"
command_check_and_install "libxml2-dev" "libxml2-dev"
command_check_and_install "libxslt1-dev" "libxslt1-dev"
command_check_and_install "zlib1g-dev" "zlib1g-dev"
command_check_and_install "libsasl2-dev" "libsasl2-dev"
command_check_and_install "libldap2-dev" "libldap2-dev"
command_check_and_install "libssl-dev" "libssl-dev"
command_check_and_install "libjpeg8-dev" "libjpeg8-dev"
command_check_and_install "liblcms2-dev" "liblcms2-dev"
command_check_and_install "libblas-dev" "libblas-dev"
command_check_and_install "libatlas-base-dev" "libatlas-base-dev"
command_check_and_install "libmysqlclient-dev" "libmysqlclient-dev"
command_check_and_install "libjpeg-dev" "libjpeg-dev"
command_check_and_install "libpq-dev" "libpq-dev"
command_check_and_install "libxml2" "libxml2"
command_check_and_install "libxmlsec1-dev" "libxmlsec1-dev"
command_check_and_install "libxslt-dev" "libxslt-dev"
command_check_and_install "certbot" "certbot"
command_check_and_install "python3-certbot-nginx" "python3-certbot-nginx"

echo ""
echo "Dependencias verificadas e instaladas si era necesario."
echo ""
echo "----------------------------------------------------------------------"

exit 0

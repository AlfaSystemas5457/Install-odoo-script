#!/bin/bash

echo ""
echo "----------------------------------------------------------------------"
echo "Instalando dependencias..."

apt update -y

apt install -y git python3 python3-venv systemd curl python3-dev python3-pip build-essential libxml2-dev libxslt1-dev zlib1g-dev libsasl2-dev libldap2-dev libssl-dev liblcms2-dev libblas-dev libjpeg-dev libpq-dev libxml2 libxmlsec1-dev libxslt-dev certbot python3-certbot-nginx zip 

echo ""
echo "Dependencias verificadas e instaladas si era necesario."
echo ""
echo "----------------------------------------------------------------------"

exit 0

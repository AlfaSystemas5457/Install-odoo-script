#!/bin/bash

echo ""
echo "----------------------------------------------------------------------"
echo "Instalando wkhtmltopdf..."

wget https://ftp.debian.org/debian/pool/main/o/openssl/libssl1.1_1.1.1w-0+deb11u1_amd64.deb
dpkg -i libssl1.1*

sudo apt remove wkhtmltopdf

wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
tar xvf wkhtmltox*.tar.xz

sudo mv wkhtmltox/bin/wkhtmlto* /usr/bin
sudo apt install -y openssl build-essential libssl-dev libxrender-dev git-core libx11-dev libxext-dev libfontconfig1-dev libfreetype6-dev fontconfig

rm -rf wkhtmltox* libssl*

echo "----------------------------------------------------------------------"
echo ""

echo "Libssl version:"
dpkg -l | grep libssl1.1

echo ""
echo "----------------------------------------------------------------------"
echo ""

echo "wkhtmltopdf version:"
wkhtmltopdf --version
echo "wkhtmltopdf instalado"

echo ""
echo "----------------------------------------------------------------------"

exit 0

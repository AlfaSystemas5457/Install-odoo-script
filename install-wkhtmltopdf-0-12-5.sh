#!/bin/bash

echo ""
echo "----------------------------------------------------------------------"
echo "Instalando wkhtmltopdf..."

cd ~
wget https://ftp.debian.org/debian/pool/main/o/openssl/libssl1.1_1.1.1w-0+deb11u1_amd64.deb
dpkg -i libssl1.1*
rm -rf libssl1.1*

sudo apt update
sudo apt install -y fontconfig libxrender1 libfreetype6 libxext6 libx11-6 xfonts-75dpi xfonts-base
sudo apt remove wkhtmltopdf

wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.stretch_amd64.deb

sudo dpkg -i wkhtmltox_0.12.5-1.stretch_amd64.deb
sudo apt --fix-broken install -y

sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin/wkhtmltopdf
sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin/wkhtmltoimage

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

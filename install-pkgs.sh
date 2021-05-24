#!/bin/bash

apt-get update

apt-get install -y gnupg curl

echo "deb http://apt.postgresql.org/pub/repos/apt groovy-pgdg main" > /etc/apt/sources.list.d/pgdg.list
curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

apt-get update

{ cat <<EOF
bison
build-essential
ca-certificates
cmake
curl
fakeroot
gcc
gcc-mingw-w64
geoip-database
git
gnutls-bin
graphviz
heimdal-dev
ike-scan
libgcrypt20-dev
libglib2.0-dev
libgnutls28-dev
libgpgme11-dev
libgpgme-dev
libhiredis-dev
libical-dev
libksba-dev
libldap2-dev
libmicrohttpd-dev
libnet1-dev
libnet-snmp-perl
libpcap-dev
libpopt-dev
libradcli-dev
libsnmp-dev
libssh-gcrypt-dev
libunistring-dev
libxml2-dev
net-tools
nmap
nsis
openssh-client
openssh-server
perl-base
pkg-config
postfix
postgresql-12
postgresql-server-dev-12
python3-defusedxml
python3-dev
python3-dialog
python3-lxml
python3-paramiko
python3-pip
python3-polib
python3-psutil
python3-setuptools
redis-server
redis-tools
rpm
rsync
smbclient
sshpass
texlive-fonts-recommended
texlive-latex-extra
uuid-dev
wapiti
wget
whiptail
xml-twig-tools
xsltproc
EOF
} | xargs apt-get install -yq --no-install-recommends


# Install Node.js
curl -sL https://deb.nodesource.com/setup_12.x | bash -
apt-get install nodejs -yq --no-install-recommends


# Install Yarn
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
apt-get update
apt-get install yarn -yq --no-install-recommends


rm -rf /var/lib/apt/lists/*

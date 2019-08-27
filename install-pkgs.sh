#!/bin/bash

apt-get update

{ cat <<EOF
alien
bison
build-essential
ca-certificates
cmake
curl
doxygen
flex
gcc
gcc-mingw-w64
geoip-database
git
graphviz
language-pack-en
libgcrypt20-dev
libglib2.0-dev
libgnutls28-dev
libgpgme11-dev
libgpgme-dev
libhiredis-dev
libical2-dev
libksba-dev
libmicrohttpd-dev
libnet-snmp-perl
libpcap-dev
libpopt-dev
libsnmp-dev
libsqlite3-dev
libssh-gcrypt-dev
libxml2-dev
net-tools
nikto
nmap
nsis
patch
perl-base heimdal-dev
pkg-config
python3-defusedxml
python3-dialog
python3-lxml
python3-paramiko
python3-setuptools
python-impacket
python-pip
python-setuptools
redis-server
redis-tools
rsync
smbclient
sqlite3
texlive-fonts-recommended
texlive-latex-extra
uuid-dev
wget
xsltproc
EOF
} | xargs apt-get install -yq --no-install-recommends


# Install Node.js
curl -sL https://deb.nodesource.com/setup_10.x | bash -
apt-get install nodejs -yq --no-install-recommends


# Install Yarn
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
apt-get update
apt-get install yarn


rm -rf /var/lib/apt/lists/*

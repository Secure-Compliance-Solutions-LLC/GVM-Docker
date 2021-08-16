#!/usr/bin/env bash
#set -Eeuo pipefail

touch /opt/setup/.env

echo 'deb http://deb.debian.org/debian buster-backports main' | tee /etc/apt/sources.list.d/backports.list
echo "Acquire:http::Proxy \"${http_proxy}\";" | tee /etc/apt/apt.conf.d/30proxy
echo "APT::Install-Recommends \"0\" ; APT::Install-Suggests \"0\" ;" | tee /etc/apt/apt.conf.d/10no-recommend-installs

apt-get update
apt-get install -yq --no-install-recommends gnupg curl wget sudo ca-certificates postfix supervisor cron openssh-server

## START Postgres
echo "deb http://apt.postgresql.org/pub/repos/apt buster-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

sudo apt-get update
sudo apt-get -yq upgrade

sudo apt-get install -y postgresql-13

sudo update-alternatives --install /usr/bin/postgres postgres /usr/lib/postgresql/13/bin/postgres 50
sudo update-alternatives --install /usr/bin/initdb initdb /usr/lib/postgresql/13/bin/initdb 50
#ln -s /usr/lib/postgresql/13/bin/postgres /usr/bin/postgres
#ln -s /usr/lib/postgresql/13/bin/initdb /usr/bin/initdb

sudo locale-gen en_US.UTF-8
sudo localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
## END Postgres

sudo rm -rf /var/lib/apt/lists/*

sudo useradd -r -M -U -G sudo -s /bin/sh gvm

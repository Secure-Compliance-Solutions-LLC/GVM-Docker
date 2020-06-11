#!/usr/bin/env bash
set -Eeuo pipefail

USERNAME=${USERNAME:-admin}
PASSWORD=${PASSWORD:-admin}

HTTPS=${HTTPS:-true}

if [ ! -d "/run/redis" ]; then
	mkdir /run/redis
fi
if  [ -S /run/redis/redis.sock ]; then
        rm /run/redis/redis.sock
fi
redis-server --unixsocket /run/redis/redis.sock --unixsocketperm 700 --timeout 0 --databases 128 --maxclients 4096 --daemonize yes --port 6379 --bind 0.0.0.0

echo "Wait for redis socket to be created..."
while  [ ! -S /run/redis/redis.sock ]; do
        sleep 1
done

echo "Testing redis status..."
X="$(redis-cli -s /run/redis/redis.sock ping)"
while  [ "${X}" != "PONG" ]; do
        echo "Redis not yet ready..."
        sleep 1
        X="$(redis-cli -s /run/redis/redis.sock ping)"
done
echo "Redis ready."


if  [ ! -d /data ]; then
	echo "Creating Data folder..."
        mkdir /data
fi

if  [ ! -d /data/database ]; then
	echo "Creating Database folder..."
	mv /var/lib/postgresql/12/main /data/database
	ln -s /data/database /var/lib/postgresql/12/main
	chown postgres:postgres -R /var/lib/postgresql/12/main
	chown postgres:postgres -R /data/database
fi

echo "Starting PostgreSQL..."
su -c "/usr/lib/postgresql/12/bin/pg_ctl -D /data/database start" postgres

if [ ! -f "/firstrun" ]; then
	echo "Running first start configuration..."

	echo "Creating Openvas NVT sync user..."
	useradd --home-dir /usr/local/share/openvas openvas-sync
	chown openvas-sync:openvas-sync -R /usr/local/share/openvas
	chown openvas-sync:openvas-sync -R /usr/local/var/lib/openvas

	echo "Creating Greenbone Vulnerability system user..."
	useradd --home-dir /usr/local/share/gvm gvm
	chown gvm:gvm -R /usr/local/share/gvm
	mkdir /usr/local/var/lib/gvm/cert-data
	chown gvm:gvm -R /usr/local/var/lib/gvm
	chmod 770 -R /usr/local/var/lib/gvm
	chown gvm:gvm -R /usr/local/var/log/gvm
	chown gvm:gvm -R /usr/local/var/run

	adduser openvas-sync gvm
	adduser gvm openvas-sync
	touch /firstrun
fi

if [ ! -f "/data/firstrun" ]; then
	echo "Creating Greenbone Vulnerability Manager database"
	su -c "createuser -DRS gvm" postgres
	su -c "createdb -O gvm gvmd" postgres
	su -c "psql --dbname=gvmd --command='create role dba with superuser noinherit;'" postgres
	su -c "psql --dbname=gvmd --command='grant dba to gvm;'" postgres
	su -c "psql --dbname=gvmd --command='create extension \"uuid-ossp\";'" postgres
	touch /data/firstrun
fi

su -c "gvmd --migrate" gvm

if  [ ! -d /data/gvmd ]; then
	echo "Creating gvmd folder..."
	mkdir /data/gvmd
	chown gvm:gvm -R /data/gvmd
fi

if  [ ! -h /usr/local/var/lib/gvm/gvmd ]; then
	echo "Fixing gvmd folder..."
	rm -rf /usr/local/var/lib/gvm/gvmd
	ln -s /data/gvmd /usr/local/var/lib/gvm/gvmd
fi

if  [ ! -d /data/certs ] && [ $HTTPS == "true" ]; then
	echo "Creating certs folder..."
	mkdir -p /data/certs/CA
	mkdir -p /data/certs/private
	
	echo "Generating certs..."
	gvm-manage-certs -a
	
	cp /usr/local/var/lib/gvm/CA/* /data/certs/CA/
	
	cp -r /usr/local/var/lib/gvm/private/* /data/certs/private/
	
	chown gvm:gvm -R /data/certs
fi

if [ ! -h /usr/local/var/lib/gvm/CA ] && [ $HTTPS == "true" ]; then
	echo "Fixing certs CA folder..."
	rm -rf /usr/local/var/lib/gvm/CA
	ln -s /data/certs/CA /usr/local/var/lib/gvm/CA
	chown gvm:gvm -R /data/certs
	chown gvm:gvm -R /usr/local/var/lib/gvm/CA
fi

if [ ! -h /usr/local/var/lib/gvm/private ] && [ $HTTPS == "true" ]; then
	echo "Fixing certs private folder..."
	rm -rf /usr/local/var/lib/gvm/private
	ln -s /data/certs/private /usr/local/var/lib/gvm/private
	chown gvm:gvm -R /data/certs
	chown gvm:gvm -R /usr/local/var/lib/gvm/private
fi

if  [ ! -d /data/plugins ]; then
	echo "Creating NVT Plugins folder..."
	mkdir /data/plugins
fi

if [ ! -h /usr/local/var/lib/openvas/plugins ]; then
	echo "Fixing NVT Plugins folder..."
	rm -rf /usr/local/var/lib/openvas/plugins
	ln -s /data/plugins /usr/local/var/lib/openvas/plugins
	chown openvas-sync:openvas-sync -R /data/plugins
	chown openvas-sync:openvas-sync -R /usr/local/var/lib/openvas/plugins
fi

if  [ ! -d /data/cert-data ]; then
	echo "Creating CERT Feed folder..."
	mkdir /data/cert-data
fi

if [ ! -h /usr/local/var/lib/gvm/cert-data ]; then
	echo "Fixing CERT Feed folder..."
	rm -rf /usr/local/var/lib/gvm/cert-data
	ln -s /data/cert-data /usr/local/var/lib/gvm/cert-data
	chown openvas-sync:openvas-sync -R /data/cert-data
	chown openvas-sync:openvas-sync -R /usr/local/var/lib/gvm/cert-data
fi

if  [ ! -d /data/scap-data ]; then
	echo "Creating SCAP Feed folder..."
	mkdir /data/scap-data
fi

if [ ! -h /usr/local/var/lib/gvm/scap-data ]; then
	echo "Fixing SCAP Feed folder..."
	rm -rf /usr/local/var/lib/gvm/scap-data
	ln -s /data/scap-data /usr/local/var/lib/gvm/scap-data
	chown openvas-sync:openvas-sync -R /data/scap-data
	chown openvas-sync:openvas-sync -R /usr/local/var/lib/gvm/scap-data
fi

echo "Updating NVTs..."
su -c "rsync --compress-level=9 --links --times --omit-dir-times --recursive --partial --quiet rsync://feed.community.greenbone.net:/nvt-feed /usr/local/var/lib/openvas/plugins" openvas-sync
sleep 5

echo "Updating CERT data..."
su -c "/cert-data-sync.sh" openvas-sync
sleep 5

echo "Updating SCAP data..."
su -c "/scap-data-sync.sh" openvas-sync

if [ -f /var/run/ospd.pid ]; then
  rm /var/run/ospd.pid
fi

if [ -S /tmp/ospd.sock ]; then
  rm /tmp/ospd.sock
fi

if [ ! -d /var/run/ospd ]; then
  mkdir /var/run/ospd
fi

echo "Starting Open Scanner Protocol daemon for OpenVAS..."
ospd-openvas --log-file /usr/local/var/log/gvm/ospd-openvas.log --unix-socket /tmp/ospd.sock --log-level INFO

while  [ ! -S /tmp/ospd.sock ]; do
	sleep 1
done

chmod 666 /tmp/ospd.sock

echo "Starting Greenbone Vulnerability Manager..."
su -c "gvmd --listen=0.0.0.0 --port=9390" gvm

until su -c "gvmd --get-users" gvm; do
	sleep 1
done

if [ ! -f "/data/created_gvm_user" ]; then
	echo "Creating Greenbone Vulnerability Manager admin user"
	su -c "gvmd --create-user=${USERNAME} --password=${PASSWORD}" gvm
	
	touch /data/created_gvm_user
fi

echo "Starting Greenbone Security Assistant..."
if [ $HTTPS == "true" ]; then
	su -c "gsad --verbose --gnutls-priorities=SECURE128:-AES-128-CBC:-CAMELLIA-128-CBC:-VERS-SSL3.0:-VERS-TLS1.0 --no-redirect --mlisten=127.0.0.1 --mport=9390 --port=9392" gvm
else
	su -c "gsad --verbose --http-only --no-redirect --mlisten=127.0.0.1 --mport=9390 --port=9392" gvm
fi
echo "++++++++++++++++++++++++++++++++++++++++++++++"
echo "+ Your GVM 11 container is now ready to use! +"
echo "++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo "++++++++++++++++"
echo "+ Tailing logs +"
echo "++++++++++++++++"
tail -F /usr/local/var/log/gvm/*

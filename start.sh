#!/usr/bin/env bash
set -Eeuo pipefail

USERNAME=${USERNAME:-admin}
PASSWORD=${PASSWORD:-admin}

if [ ! -d "/run/redis" ]; then
	mkdir /run/redis
fi
redis-server --unixsocket /run/redis/redis.sock --unixsocketperm 700 --timeout 0 --databases 128 --maxclients 512 --daemonize yes --port 6379 --bind 0.0.0.0

echo "Testing redis status..."
X="$(redis-cli -s /run/redis/redis.sock ping)"
while  [ "${X}" != "PONG" ]; do
        echo "Redis not yet ready..."
        sleep 1
        X="$(redis-cli -s /run/redis/redis.sock ping)"
done
echo "Redis ready."

echo "Starting PostgreSQL..."
/usr/bin/pg_ctlcluster --skip-systemctl-redirect 10 main start

if [ ! -f "/firstrun" ]; then
  echo "Running first start configuration..."
  
  echo "Creating Openvas NVT sync user"
  useradd --home-dir /usr/local/share/openvas openvas-sync
  chown openvas-sync:openvas-sync -R /usr/local/share/openvas
  chown openvas-sync:openvas-sync -R /usr/local/var/lib/openvas
  
  echo "Creating Greenbone Vulnerability system user"
  useradd --home-dir /usr/local/share/gvm gvm
  chown gvm:gvm -R /usr/local/share/gvm
  mkdir /usr/local/var/lib/gvm/cert-data
  chown gvm:gvm -R /usr/local/var/lib/gvm
  chmod 770 -R /usr/local/var/lib/gvm
  chown gvm:gvm -R /usr/local/var/log/gvm
  chown gvm:gvm -R /usr/local/var/run
  
  echo "Creating Greenbone Vulnerability Manager database"
  su -c "createuser -DRS gvm" postgres
  su -c "createdb -O gvm gvmd" postgres
  su -c "psql --dbname=gvmd --command='create role dba with superuser noinherit;'" postgres
  su -c "psql --dbname=gvmd --command='grant dba to gvm;'" postgres
  su -c "psql --dbname=gvmd --command='create extension \"uuid-ossp\";'" postgres
  
  adduser openvas-sync gvm
  adduser gvm openvas-sync
  touch /firstrun
fi

echo "Updating NVTs..."
su -c "greenbone-nvt-sync > /dev/null" openvas-sync

echo "Updating CERT data..."
su -c "greenbone-certdata-sync > /dev/null" openvas-sync

echo "Updating SCAP data..."
su -c "greenbone-scapdata-sync > /dev/null" openvas-sync

rm /tmp/gvm-sync-*

if [ -f /var/run/ospd.pid ]; then
  rm /var/run/ospd.pid
fi

echo "Starting Open Scanner Protocol daemon for OpenVAS..."
ospd-openvas --log-file /usr/local/var/log/gvm/ospd-openvas.log --unix-socket /tmp/ospd.sock --log-level INFO

while  [ ! -S /tmp/ospd.sock ]; do
	sleep 1
done

chmod 777 /tmp/ospd.sock

echo "Starting Greenbone Vulnerability Manager..."
su -c "gvmd" gvm

until su -c "gvmd --get-users" gvm; do
	sleep 1
done

if [ ! -f "/created_gvm_user" ]; then
	echo "Creating Greenbone Vulnerability Manager admin user"
	su -c "gvmd --create-user=${USERNAME} --password=${PASSWORD}" gvm
	
	touch /created_gvm_user
fi

echo "Starting Greenbone Security Assistant..."
su -c "gsad --verbose --http-only --no-redirect --port=9392" gvm

echo "++++++++++++++++++++++++++++++++++++++++++++++"
echo "+ Your GVM 11 container is now ready to use! +"
echo "++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo "++++++++++++++++"
echo "+ Tailing logs +"
echo "++++++++++++++++"
tail -F /usr/local/var/log/gvm/*

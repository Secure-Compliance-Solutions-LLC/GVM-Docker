#!/usr/bin/env bash

DATAVOL=/var/lib/openvas/mgr/
USERNAME=${USERNAME:-admin}
PASSWORD=${PASSWORD:-admin}

redis-server --unixsocket /run/redis/redis.sock --unixsocketperm 700 --timeout 0 --databases 128 --maxclients 512 --daemonize yes --port 6379 --bind 0.0.0.0

echo "Testing redis status..."
X="$(redis-cli -s /run/redis/redis.sock ping)"
while  [ "${X}" != "PONG" ]; do
        echo "Redis not yet ready..."
        sleep 1
        X="$(redis-cli -s /run/redis/redis.sock ping)"
done
echo "Redis ready."

if [ ! -f "$PGLOG/postgres.log" ]; then
	echo "Setting up database"
	sudo -u postgres /usr/lib/postgresql/10/bin/initdb -D $PGDATA
	sudo -u postgres /usr/lib/postgresql/10/bin/pg_ctl -D $PGDATA -l $PGLOG/postgres.log start
	sudo -u postgres /home/greenbone/createdb.sh
else
	echo "Starting database"
	sudo -u postgres rm $PGDATA/postmaster.pid
	sudo -u postgres /usr/lib/postgresql/10/bin/pg_ctl -D $PGDATA -l $PGLOG/postgres.log start
fi

echo "Starting services"
rm -f /usr/local/var/run/ospd.pid
ospd-openvas -u /tmp/ospd.sock -l /usr/local/var/log/gvm/ospd-openvas.log --pid-file /usr/local/var/run/ospd.pid
gvmd
gsad --verbose --http-only --no-redirect --port=9392

echo "Update NVTs"
greenbone-nvt-sync --curl

nc -w 5 89.146.224.58 873 && rsync=1 || rsync=0
if [ "$rsync" == "0" ]; then 
	echo rsync unavailable
else 
	echo rsync available
	echo "Update Cert data"
	greenbone-certdata-sync
	echo "Update SCAP data"
	greenbone-scapdata-sync
fi

if [ ! -f "/home/greenbone/firstrun" ]; then
	echo "Creating OpenVAS scanner"
	gvmd --create-scanner="OSP Scanner" --scanner-type="OSP" --scanner-host=/tmp/ospd.sock
  	echo "Setting up user"
  	gvmd --create-user=${USERNAME} --password=${PASSWORD}
  	touch /home/greenbone/firstrun
fi

echo "Tailing OpenVAS logs for your convenience"
tail -F /usr/local/var/log/gvm/*

echo "Your OpenVAS container is now ready to use!"
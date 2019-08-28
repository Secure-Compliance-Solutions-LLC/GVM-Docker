#!/usr/bin/env bash

DATAVOL=/var/lib/openvas/mgr/
USERNAME=${USERNAME:-admin}
PASSWORD=${PASSWORD:-admin}

redis-server --unixsocket /tmp/redis.sock --unixsocketperm 700 --timeout 0 --databases 128 --maxclients 512 --daemonize yes --port 6379 --bind 0.0.0.0

echo "Testing redis status..."
X="$(redis-cli -s /tmp/redis.sock ping)"
while  [ "${X}" != "PONG" ]; do
        echo "Redis not yet ready..."
        sleep 1
        X="$(redis-cli -s /tmp/redis.sock ping)"
done
echo "Redis ready."

echo "Starting services"
openvassd
gvmd
gsad --verbose --http-only --no-redirect --port=9392

echo "Update NVTs"
greenbone-nvt-sync
greenbone-certdata-sync
greenbone-scapdata-sync

if [ ! -f "/firstrun" ]; then
  echo "Setting up user"
  gvmd --create-user=${USERNAME} --password=${PASSWORD}
  touch /firstrun
fi

echo "Tailing OpenVAS logs for your convenience"
tail -F /usr/local/var/log/gvm/*

echo "Your OpenVAS container is now ready to use!"
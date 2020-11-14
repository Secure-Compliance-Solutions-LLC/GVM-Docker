#!/usr/bin/env bash
set -Eeuo pipefail

USERNAME=${USERNAME:-admin}
PASSWORD=${PASSWORD:-admin}
TIMEOUT=${TIMEOUT:-15}
RELAYHOST=${RELAYHOST:-smtp}
SMTPPORT=${SMTPPORT:-25}

HTTPS=${HTTPS:-true}
TZ=${TZ:-UTC}
SSHD=${SSHD:-false}
DB_PASSWORD=${DB_PASSWORD:-none}

if [ ! -d "/run/redis" ]; then
	mkdir /run/redis
fi
if  [ -S /run/redis/redis.sock ]; then
        rm /run/redis/redis.sock
fi
redis-server --unixsocket /run/redis/redis.sock --unixsocketperm 700 --timeout 0 --databases 512 --maxclients 4096 --daemonize yes --port 6379 --bind 0.0.0.0

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
	mkdir /data/database
	chown postgres:postgres -R /data/database
	su -c "/usr/lib/postgresql/12/bin/initdb /data/database" postgres
fi

chown postgres:postgres -R /data/database

echo "Starting PostgreSQL..."
su -c "/usr/lib/postgresql/12/bin/pg_ctl -D /data/database start" postgres

if  [ ! -d /data/ssh ]; then
	echo "Creating SSH folder..."
	mkdir /data/ssh
	
	rm -rf /etc/ssh/ssh_host_*
	
	dpkg-reconfigure openssh-server
	
	mv /etc/ssh/ssh_host_* /data/ssh/
fi

if  [ ! -h /etc/ssh ]; then
	rm -rf /etc/ssh
	ln -s /data/ssh /etc/ssh
fi

if [ ! -f "/firstrun" ]; then
	echo "Running first start configuration..."
	
	ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

	echo "Creating Greenbone Vulnerability system user..."
	useradd --home-dir /usr/local/share/gvm gvm
	
	chown gvm:gvm -R /usr/local/share/openvas
	chown gvm:gvm -R /usr/local/var/lib/openvas
	
	chown gvm:gvm -R /usr/local/share/gvm
	
	mkdir /usr/local/var/lib/gvm/cert-data
	
	chown gvm:gvm -R /usr/local/var/lib/gvm
	chmod 770 -R /usr/local/var/lib/gvm
	
	chown gvm:gvm -R /usr/local/var/log/gvm
	
	chown gvm:gvm -R /usr/local/var/run
	
	touch /firstrun
fi

if [ ! -f "/data/firstrun" ]; then
	echo "Creating Greenbone Vulnerability Manager database"
	su -c "createuser -DRS gvm" postgres
	su -c "createdb -O gvm gvmd" postgres
	su -c "psql --dbname=gvmd --command='create role dba with superuser noinherit;'" postgres
	su -c "psql --dbname=gvmd --command='grant dba to gvm;'" postgres
	su -c "psql --dbname=gvmd --command='create extension \"uuid-ossp\";'" postgres
	su -c "psql --dbname=gvmd --command='create extension \"pgcrypto\";'" postgres
	
	echo "listen_addresses = '*'" >> /data/database/postgresql.conf
	echo "port = 5432" >> /data/database/postgresql.conf
	
	echo "host    all             all              0.0.0.0/0                 md5" >> /data/database/pg_hba.conf
	echo "host    all             all              ::/0                      md5" >> /data/database/pg_hba.conf
	
	chown postgres:postgres -R /data/database
	
	su -c "/usr/lib/postgresql/12/bin/pg_ctl -D /data/database restart" postgres
	
	touch /data/firstrun
fi

su -c "gvmd --migrate" gvm

if [ $DB_PASSWORD != "none" ]; then
	su -c "psql --dbname=gvmd --command=\"alter user gvm password '$DB_PASSWORD';\"" postgres
fi

if  [ ! -d /data/gvmd ]; then
	echo "Creating gvmd folder..."
	mkdir /data/gvmd
	cp -r /report_formats /data/gvmd/
fi

if  [ ! -h /usr/local/var/lib/gvm/gvmd ]; then
	echo "Fixing gvmd folder..."
	rm -rf /usr/local/var/lib/gvm/gvmd
	ln -s /data/gvmd /usr/local/var/lib/gvm/gvmd
	
	chown gvm:gvm -R /data/gvmd
	chown gvm:gvm -R /usr/local/var/lib/gvm/gvmd
fi

if  [ ! -d /data/certs ]; then
	echo "Creating certs folder..."
	mkdir -p /data/certs/CA
	mkdir -p /data/certs/private
	
	echo "Generating certs..."
	gvm-manage-certs -a
	
	cp /usr/local/var/lib/gvm/CA/* /data/certs/CA/
	
	cp -r /usr/local/var/lib/gvm/private/* /data/certs/private/
	
	chown gvm:gvm -R /data/certs
fi

if [ ! -h /usr/local/var/lib/gvm/CA ]; then
	echo "Fixing certs CA folder..."
	rm -rf /usr/local/var/lib/gvm/CA
	ln -s /data/certs/CA /usr/local/var/lib/gvm/CA
	
	chown gvm:gvm -R /data/certs
	chown gvm:gvm -R /usr/local/var/lib/gvm/CA
fi

if [ ! -h /usr/local/var/lib/gvm/private ]; then
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
	chown gvm:gvm -R /data/plugins
	chown gvm:gvm -R /usr/local/var/lib/openvas/plugins
fi

if  [ ! -d /data/cert-data ]; then
	echo "Creating CERT Feed folder..."
	mkdir /data/cert-data
fi

if [ ! -h /usr/local/var/lib/gvm/cert-data ]; then
	echo "Fixing CERT Feed folder..."
	rm -rf /usr/local/var/lib/gvm/cert-data
	ln -s /data/cert-data /usr/local/var/lib/gvm/cert-data
	chown gvm:gvm -R /data/cert-data
	chown gvm:gvm -R /usr/local/var/lib/gvm/cert-data
fi

if  [ ! -d /data/scap-data ]; then
	echo "Creating SCAP Feed folder..."
	
	mkdir /data/scap-data
fi

if [ ! -h /usr/local/var/lib/gvm/scap-data ]; then
	echo "Fixing SCAP Feed folder..."
	
	rm -rf /usr/local/var/lib/gvm/scap-data
	
	ln -s /data/scap-data /usr/local/var/lib/gvm/scap-data
	
	chown gvm:gvm -R /data/scap-data
	chown gvm:gvm -R /usr/local/var/lib/gvm/scap-data
fi

if  [ ! -d /data/data-objects/gvmd ]; then
	echo "Creating GVMd Data Objects folder..."
	
	mkdir -p /data/data-objects/gvmd
fi

if [ ! -h /usr/local/var/lib/gvm/data-objects ]; then
	echo "Fixing GVMd Data Objects folder..."
	
	rm -rf /usr/local/var/lib/gvm/data-objects
	
	ln -s /data/data-objects /usr/local/var/lib/gvm/data-objects
	
	chown gvm:gvm -R /data/data-objects
	chown gvm:gvm -R /usr/local/var/lib/gvm/data-objects
fi

# Sync NVTs, CERT data, and SCAP data on container start
/sync-all.sh

###########################
#Remove leftover pid files#
###########################

if [ -f /var/run/ospd.pid ]; then
  rm /var/run/ospd.pid
fi

if [ -S /tmp/ospd.sock ]; then
  rm /tmp/ospd.sock
fi

if [ ! -d /var/run/ospd ]; then
  mkdir /var/run/ospd
fi

echo "Starting Postfix for report delivery by email"
sed -i "s/^relayhost.*$/relayhost = ${RELAYHOST}:${SMTPPORT}/" /etc/postfix/main.cf
service postfix start

echo "Starting Open Scanner Protocol daemon for OpenVAS..."
ospd-openvas --log-file /usr/local/var/log/gvm/ospd-openvas.log --unix-socket /var/run/ospd/ospd.sock --log-level INFO

while  [ ! -S /var/run/ospd/ospd.sock ]; do
	sleep 1
done

chmod 666 /var/run/ospd/ospd.sock

echo "Creating OSPd socket link from old location..."
rm -rf /tmp/ospd.sock
ln -s /var/run/ospd/ospd.sock /tmp/ospd.sock

echo "Starting Greenbone Vulnerability Manager..."
su -c "gvmd --listen=0.0.0.0 --port=9390" gvm

echo "Waiting for Greenbone Vulnerability Manager to finish startup..."
until su -c "gvmd --get-users" gvm; do
	sleep 1
done

if [ ! -f "/data/created_gvm_user" ]; then
	echo "Creating Greenbone Vulnerability Manager admin user"
	su -c "gvmd --role=\"Super Admin\" --create-user=\"$USERNAME\" --password=\"$PASSWORD\"" gvm
	
	USERSLIST=$(su -c "gvmd --get-users --verbose" gvm)
	IFS=' '
	read -ra ADDR <<<"$USERSLIST"
	
	echo "${ADDR[1]}"
	
	su -c "gvmd --modify-setting 78eceaec-3385-11ea-b237-28d24461215b --value ${ADDR[1]}" gvm
	
	touch /data/created_gvm_user
fi

echo "Starting Greenbone Security Assistant..."
if [ $HTTPS == "true" ]; then
	su -c "gsad --verbose --gnutls-priorities=SECURE128:-AES-128-CBC:-CAMELLIA-128-CBC:-VERS-SSL3.0:-VERS-TLS1.0 --timeout=$TIMEOUT --no-redirect --mlisten=127.0.0.1 --mport=9390 --port=9392" gvm
else
	su -c "gsad --verbose --http-only --timeout=$TIMEOUT --no-redirect --mlisten=127.0.0.1 --mport=9390 --port=9392" gvm
fi

if [ $SSHD == "true" ]; then
	echo "Starting OpenSSH Server..."
	
	if  [ ! -d /data/scanner-ssh-keys ]; then
		echo "Creating scanner SSH keys folder..."
		mkdir /data/scanner-ssh-keys
		chown gvm:gvm -R /data/scanner-ssh-keys
	fi
	if [ ! -h /usr/local/share/gvm/.ssh ]; then
		echo "Fixing scanner SSH keys folder..."
		rm -rf /usr/local/share/gvm/.ssh
		ln -s /data/scanner-ssh-keys /usr/local/share/gvm/.ssh
		chown gvm:gvm -R /data/scanner-ssh-keys
		chown gvm:gvm -R /usr/local/share/gvm/.ssh
	fi
	
	if [ ! -d /sockets ]; then
		mkdir /sockets
		chown gvm:gvm -R /sockets
	fi
	
	echo "gvm:gvm" | chpasswd
	
	rm -rf /var/run/sshd
	mkdir -p /var/run/sshd
	
	/usr/sbin/sshd -f /sshd_config -E /usr/local/var/log/gvm/sshd.log
fi

echo "++++++++++++++++++++++++++++++++++++++++++++++"
echo "+ Your GVM 20.04 container is now ready to use! +"
echo "++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo "-----------------------------------------------------------"
echo "Server Public key: $(cat /etc/ssh/ssh_host_ed25519_key.pub)"
echo "-----------------------------------------------------------"
echo ""
echo "++++++++++++++++"
echo "+ Tailing logs +"
echo "++++++++++++++++"
tail -F /usr/local/var/log/gvm/*

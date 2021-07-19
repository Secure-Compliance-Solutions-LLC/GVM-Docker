#!/usr/bin/env bash
set -Eeuo pipefail

export SUPVISD=${SUPVISD:-supervisorctl}
export USERNAME=${USERNAME:-${GVMD_USER:-admin}}
export PASSWORD=${PASSWORD:-${GVMD_PASSWORD:-adminpassword}}
export PASSWORD_FILE=${PASSWORD_FILE:-${GVMD_PASSWORD_FILE:-none}}
export TIMEOUT=${TIMEOUT:-15}
export DEBUG=${DEBUG:-N}
export RELAYHOST=${RELAYHOST:-smtp}
export SMTPPORT=${SMTPPORT:-25}
export AUTO_SYNC=${AUTO_SYNC:-true}
export HTTPS=${HTTPS:-true}
export CERTIFICATE=${CERTIFICATE:-none}
export CERTIFICATE_KEY=${CERTIFICATE_KEY:-none}
export TZ=${TZ:-Etc/UTC}
export SSHD=${SSHD:-false}
export DB_PASSWORD=${DB_PASSWORD:-none}
export DB_PASSWORD_FILE=${DB_PASSWORD_FILE:-none}
export OPT_PDF=${OPT_PDF:-0}

if [ "${OPT_PDF}" == "1" ]; then
	apk add --no-cache --allow-untrusted texlive texmf-dist-latexextra texmf-dist-fontsextra
fi

mkdir -p /var/lib/gvm
mkdir -p /var/lib/gvm/CA
mkdir -p /var/lib/gvm/cert-data
mkdir -p /var/lib/gvm/data-objects/gvmd
mkdir -p /var/lib/gvm/gvmd
mkdir -p /var/lib/gvm/private
mkdir -p /var/lib/gvm/scap-data
chown gvm:gvm -R /var/lib/gvm

## This need on HyperVisor for GVM
#echo 'never' >/sys/kernel/mm/transparent_hugepage/enabled
#echo 'never' >/sys/kernel/mm/transparent_hugepage/defrag

if [ ! -d "/run/redis" ]; then
	mkdir /run/redis
fi

if [ -S /run/redis/redis.sock ]; then
	rm /run/redis/redis.sock
fi

if [ ! -d "/run/redis-openvas" ]; then
	echo "create /run/redis-openvas"
	mkdir /run/redis-openvas
fi

if [ -S /run/redis-openvas/redis.sock ]; then
	rm /run/redis-openvas/redis.sock
fi

${SUPVISD} start redis
if [ "${DEBUG}" == "Y" ]; then
	${SUPVISD} status redis
fi

echo "Wait for redis socket to be created..."
while [ ! -S /run/redis-openvas/redis.sock ]; do
	sleep 1
done

echo "Testing redis status..."
X="$(redis-cli -s /run/redis-openvas/redis.sock ping)"
while [ "${X}" != "PONG" ]; do
	echo "Redis not yet ready..."
	sleep 1
	X="$(redis-cli -s /run/redis-openvas/redis.sock ping)"
done
echo "Redis ready."

if [ ! -d "/opt/database/" ] || ([ -d "/opt/database/" ] && [ "$(find /opt/database/ -maxdepth 0 -empty)" ]); then
	echo "Creating Database folder..."
	mkdir -p /opt/database
	mkdir -p /run/postgresql
	chown postgres:postgres -R /opt/database
	chown postgres:postgres -R /run/postgresql/

	su -c "initdb -D /opt/database" postgres
	{
		echo "listen_addresses = '*'"
		echo "port = 5432"
		echo "jit = off"
	} >>/opt/database/postgresql.conf

	{
		echo "host    all             all              0.0.0.0/0                 md5"
		echo "host    all             all              ::/0                      md5"
	} >>/opt/database/pg_hba.conf
fi
sleep 1
chown postgres:postgres -R /opt/database
mkdir -p /run/postgresql
chown postgres:postgres -R /run/postgresql/
sleep 2
echo "Starting PostgreSQL..."
${SUPVISD} start postgresql
if [ "${DEBUG}" == "Y" ]; then
	${SUPVISD} status postgresql
fi

until (pg_isready --username=postgres >/dev/null 2>&1 && psql --username=postgres --list >/dev/null 2>&1); do
	sleep 1
done

if [[ ! -d "/etc/ssh" ]] || [[ -d "/etc/ssh/" && $(find /etc/ssh/ -maxdepth 0 -empty) ]]; then
	mkdir /etc/ssh
	ssh-keygen -A
fi
echo "Generate SSH-HOST Keys"
ssh-keygen -A

if [ ! -f "/opt/database/.firstrun" ]; then
	echo "Creating Greenbone Vulnerability Manager database"
	su -c "createuser -DRS gvm" postgres
	su -c "createdb -O gvm gvmd" postgres
	su -c "psql --dbname=gvmd --command='create role dba with superuser noinherit;'" postgres
	su -c "psql --dbname=gvmd --command='grant dba to gvm;'" postgres
	su -c "psql --dbname=gvmd --command='create extension \"uuid-ossp\";'" postgres
	su -c "psql --dbname=gvmd --command='create extension \"pgcrypto\";'" postgres

	{
		echo "listen_addresses = '*'"
		echo "port = 5432"
		echo "jit = off"
	} >>/opt/database/postgresql.conf

	{
		echo "host    all             all              0.0.0.0/0                 md5"
		echo "host    all             all              ::/0                      md5"
	} >>/opt/database/pg_hba.conf

	chown postgres:postgres -R /opt/database

	${SUPVISD} restart postgresql
	if [ "${DEBUG}" == "Y" ]; then
		${SUPVISD} status postgresql
	fi

	touch /opt/database/.firstrun
fi

if [ ! -f "/opt/database/.upgrade_to_21.4.0" ]; then
	su -c "psql --dbname=gvmd --command='CREATE TABLE IF NOT EXISTS vt_severities (id SERIAL PRIMARY KEY,vt_oid text NOT NULL,type text NOT NULL, origin text,date integer,score double precision,value text);'" postgres
	su -c "psql --dbname=gvmd --command='ALTER TABLE vt_severities ALTER COLUMN score SET DATA TYPE double precision;'" postgres
	su -c "psql --dbname=gvmd --command='UPDATE vt_severities SET score = round((score / 10.0)::numeric, 1);'" postgres
	su -c "psql --dbname=gvmd --command='ALTER TABLE vt_severities OWNER TO gvm;'" postgres
	touch /opt/database/.upgrade_to_21.4.0
fi

if [ ! -d "/run/gvmd" ]; then
	mkdir /run/gvmd
	chown gvm:gvm -R /run/gvmd/
fi

echo "gvmd --migrate"
su -c "gvmd --migrate" gvm

if [ "$DB_PASSWORD_FILE" != "none" ] && [ -e "$DB_PASSWORD_FILE" ]; then
	su -c "psql --dbname=gvmd --command=\"alter user gvm password '$(<"$DB_PASSWORD_FILE")';\"" postgres
elif [ "$DB_PASSWORD" != "none" ]; then
	su -c "psql --dbname=gvmd --command=\"alter user gvm password '$DB_PASSWORD';\"" postgres
fi

echo "Creating gvmd folder..."
su -c "mkdir -p /var/lib/gvm/gvmd/report_formats" gvm
cp -r /report_formats /var/lib/gvm/gvmd/
chown gvm:gvm -R /var/lib/gvm
find /var/lib/gvm/gvmd/report_formats -type f -name "generate" -exec chmod +x {} \;

if [ ! -d /var/lib/gvm/CA ] || [ ! -d /var/lib/gvm/private ] || [ ! -d /var/lib/gvm/private/CA ] ||
	[ ! -f /var/lib/gvm/CA/cacert.pem ] || [ ! -f /var/lib/gvm/CA/clientcert.pem ] ||
	[ ! -f /var/lib/gvm/CA/servercert.pem ] || [ ! -f /var/lib/gvm/private/CA/cakey.pem ] ||
	[ ! -f /var/lib/gvm/private/CA/clientkey.pem ] || [ ! -f /var/lib/gvm/private/CA/serverkey.pem ]; then
	echo "Creating certs folder..."
	mkdir -p /var/lib/gvm/CA
	mkdir -p /var/lib/gvm/private

	echo "Generating certs..."
	gvm-manage-certs -a

	chown gvm:gvm -R /var/lib/gvm/
fi

# Sync NVTs, CERT data, and SCAP data on container start
# See this as a super fallback to have at least some data, even if it is then out of date.
/sync-initial.sh

#############################
# Remove leftover pid files #
#############################

if [ -f /var/run/ospd.pid ]; then
	rm /var/run/ospd.pid
fi

if [ -S /tmp/ospd.sock ]; then
	rm /tmp/ospd.sock
fi

if [ -S /var/run/ospd/ospd.sock ]; then
	rm /var/run/ospd/ospd.sock
fi

if [ ! -d /var/run/ospd ]; then
	mkdir /var/run/ospd
fi

echo "Starting Open Scanner Protocol daemon for OpenVAS..."
${SUPVISD} start ospd-openvas
if [ "${DEBUG}" == "Y" ]; then
	${SUPVISD} status ospd-openvas
fi

while [ ! -S /var/run/ospd/ospd.sock ]; do
	sleep 1
done

# echo "Creating OSPd socket link from old location..."
# rm -rfv /tmp/ospd.sock
# ln -s /var/run/ospd/ospd.sock /tmp/ospd.sock

echo "Starting Greenbone Vulnerability Manager..."
${SUPVISD} start gvmd
if [ "${DEBUG}" == "Y" ]; then
	${SUPVISD} status gvmd
fi

echo "Waiting for Greenbone Vulnerability Manager to finish startup..."
until su -c "gvmd --get-users" gvm; do
	sleep 1
done

if [ ! -f "/var/lib/gvm/.created_gvm_user" ]; then
	echo "Creating Greenbone Vulnerability Manager admin user"
	if [ "$PASSWORD_FILE" != "none" ] && [ -e "$PASSWORD_FILE" ]; then
		su -c "gvmd --role=\"Super Admin\" --create-user=\"$USERNAME\" --password=\"$(<"$PASSWORD_FILE")\"" gvm
	else
		su -c "gvmd --role=\"Super Admin\" --create-user=\"$USERNAME\" --password=\"$PASSWORD\"" gvm
	fi
	USERSLIST=$(su -c "gvmd --get-users --verbose" gvm)
	IFS=' '
	read -ra ADDR <<<"$USERSLIST"

	echo "${ADDR[1]}"

	su -c "gvmd --modify-setting 78eceaec-3385-11ea-b237-28d24461215b --value ${ADDR[1]}" gvm

	touch /var/lib/gvm/.created_gvm_user
fi

echo "Starting Greenbone Security Assistant..."
if [ "${HTTPS}" == "true" ] && [ -e "${CERTIFICATE}" ] && [ -e "${CERTIFICATE_KEY}" ]; then
	${SUPVISD} start gsad-https-owncert
	if [ "${DEBUG}" == "Y" ]; then
		${SUPVISD} status gsad-https-owncert
	fi
elif [ "${HTTPS}" == "true" ]; then
	${SUPVISD} start gsad-https
	if [ "${DEBUG}" == "Y" ]; then
		${SUPVISD} status gsad-https
	fi
else
	${SUPVISD} start gsad
	if [ "${DEBUG}" == "Y" ]; then
		${SUPVISD} status gsad
	fi
fi

if [ "$SSHD" == "true" ]; then
	echo "Starting OpenSSH Server..."
	if [ ! -d /var/lib/gvm/.ssh ]; then
		echo "Creating scanner SSH keys folder..."
		mkdir /var/lib/gvm/.ssh
		chown gvm:gvm -R /var/lib/gvm/.ssh
	fi
	if [ ! -d /sockets ]; then
		mkdir /sockets
		chown gvm:gvm -R /sockets
	fi
	echo "gvm:gvm" | chpasswd
	rm -rfv /var/run/sshd
	mkdir -p /var/run/sshd
	if [ ! -f /etc/ssh/sshd_config ]; then
		mv /sshd_config /etc/ssh/sshd_config
	fi
	${SUPVISD} start sshd
	if [ "${DEBUG}" == "Y" ]; then
		${SUPVISD} status sshd
	fi
fi

${SUPVISD} start GVMUpdate
if [ "${DEBUG}" == "Y" ]; then
	${SUPVISD} status GVMUpdate
fi
GVMVER=$(su -c "gvmd --version" gvm)
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+     $GVMVER"
echo "+ Your GVM container is now ready to use!                 +"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo "-----------------------------------------------------------"
echo "Server Public key: $(cat /etc/ssh/ssh_host_ed25519_key.pub)"
echo "-----------------------------------------------------------"
echo "-----------------------------------------------------------"
echo "+        Find logs at: /var/log/supervisor/               +"
echo "+              and at: /var/log/gvm/                      +"
echo "==========================================================="

if [ "${SETUP}" == "1" ]; then
	${SUPVISD} shutdown || true
fi

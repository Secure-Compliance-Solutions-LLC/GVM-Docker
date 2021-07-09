#!/usr/bin/env bash

if [ ! -f "/var/lib/gvm/.firstsync" ] && [ -f "/opt/gvm-sync-data.tar.xz" ]; then
	mkdir /tmp/data

	echo "Extracting internal data TAR..."
	tar --extract --file=/opt/gvm-sync-data.tar.xz --directory=/tmp/data

	chown gvm:gvm -R /tmp/data

	#	ls -lahR /tmp/data

	cp -a /tmp/data/nvt-feed/* /var/lib/openvas/plugins/
	cp -a /tmp/data/data-objects/* /var/lib/gvm/data-objects/
	cp -a /tmp/data/scap-data/* /var/lib/gvm/scap-data/
	cp -a /tmp/data/cert-data/* /var/lib/gvm/cert-data/

	chown gvm:gvm -R /var/lib/gvm
	chown gvm:gvm -R /var/lib/openvas
	chown gvm:gvm -R /var/log/gvm

	find /var/lib/openvas/ -type d -exec chmod 755 {} +
	find /var/lib/gvm/ -type d -exec chmod 755 {} +
	find /var/lib/openvas/ -type f -exec chmod 644 {} +
	find /var/lib/gvm/ -type f -exec chmod 644 {} +

	if [ "${SETUP}" == "0" ]; then
		rm /opt/gvm-sync-data.tar.xz
	fi
	rm -r /tmp/data
fi

# Sync NVTs, CERT data, and SCAP data on container start
/sync-all.sh
touch /var/lib/gvm/.firstsync

true

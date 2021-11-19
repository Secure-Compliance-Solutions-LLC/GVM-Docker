#!/usr/bin/env bash

exec_as_gvm(){
	# if root
	if [ "$EUID" -eq 0 ]; then
		su -c "$1" gvm
		return
	elif [ "$(whoami)" = "gvm" ]; then
		eval "$1"
		return
	else
		echo "Run this script either as root or as gvm user"
	fi

	false
}

if [ ! -f "/var/lib/gvm/.firstsync" ]; then
	echo "Downloading data TAR to speed up first sync..."
	curl -o /tmp/data.tar.xz https://vulndata.securecompliance.solutions/file/VulnData/data.tar.xz # This file is updated at 0:00 UTC every day
	mkdir /tmp/data

	echo "Extracting data TAR..."
	tar --extract --file=/tmp/data.tar.xz --directory=/tmp/data

	chown gvm:gvm -R /tmp/data
	#	ls -lahR /tmp/data

	cp -a /tmp/data/nvt-feed/* /var/lib/openvas/plugins
	cp -a /tmp/data/gvmd-data/* /var/lib/gvm/data-objects/gvmd
	cp -a /tmp/data/scap-data/* /var/lib/gvm/scap-data
	cp -a /tmp/data/cert-data/* /var/lib/gvm/cert-data

	chown gvm:gvm -R /var/lib/gvm
	chown gvm:gvm -R /var/lib/openvas
	chown gvm:gvm -R /var/log/gvm

	find /var/lib/openvas/ -type d -exec chmod 755 {} +
	find /var/lib/gvm/ -type d -exec chmod 755 {} +
	find /var/lib/openvas/ -type f -exec chmod 644 {} +
	find /var/lib/gvm/ -type f -exec chmod 644 {} +
	find /var/lib/gvm/gvmd/report_formats -type f -name "generate" -exec chmod +x {} \;

	rm /tmp/data.tar.xz
	rm -r /tmp/data
fi

echo "Updating NVTs..."
#su -c "rsync --compress-level=9 --links --times --omit-dir-times --recursive --partial --quiet rsync://feed.community.greenbone.net:/nvt-feed /var/lib/openvas/plugins" gvm
exec_as_gvm "greenbone-nvt-sync"
sleep 5

echo "Updating GVMd data..."
exec_as_gvm "greenbone-feed-sync --type GVMD_DATA"
sleep 5

echo "Updating SCAP data..."
exec_as_gvm "greenbone-feed-sync --type SCAP"
sleep 5

echo "Updating CERT data..."
exec_as_gvm "greenbone-feed-sync --type CERT"

true

#!/usr/bin/env bash

if [ ! -f "/data/firstsync" ]; then
	echo "Downloading data TAR to speed up first sync..."
	curl -o /tmp/data.tar.xz https://vulndata.securecompliance.solutions/file/VulnData/data.tar.xz # This file is updated at 0:00 UTC every day
	mkdir /tmp/data
	
	echo "Extracting data TAR..."
	tar --extract --file=/tmp/data.tar.xz --directory=/tmp/data
	
	mv /tmp/data/nvt-feed/* /usr/local/var/lib/openvas/plugins
	mv /tmp/data/gvmd-data/* /usr/local/var/lib/gvm/data-objects
	mv /tmp/data/scap-data/* /usr/local/var/lib/gvm/scap-data
	mv /tmp/data/cert-data/* /usr/local/var/lib/gvm/cert-data
	
	chown gvm:gvm -R /usr/local/var/lib/openvas/plugins
	chown gvm:gvm -R /usr/local/var/lib/gvm/data-objects
	chown gvm:gvm -R /usr/local/var/lib/gvm/scap-data
	chown gvm:gvm -R /usr/local/var/lib/gvm/cert-data
	
	rm /tmp/data.tar.xz
	rm -r /tmp/data
fi

echo "Updating NVTs..."
su -c "rsync --compress-level=9 --links --times --omit-dir-times --recursive --partial --quiet rsync://feed.community.greenbone.net:/nvt-feed /usr/local/var/lib/openvas/plugins" gvm
sleep 5

echo "Updating GVMd data..."
su -c "greenbone-feed-sync --type GVMD_DATA" gvm
sleep 5

echo "Updating SCAP data..."
su -c "greenbone-feed-sync --type SCAP" gvm
sleep 5

echo "Updating CERT data..."
su -c "greenbone-feed-sync --type CERT" gvm

#!/usr/bin/env bash

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
su -c "rsync --compress-level=9 --links --times --omit-dir-times --recursive --partial --quiet rsync://feed.community.greenbone.net:/nvt-feed /var/lib/openvas/plugins" gvm
sleep 5

echo "Updating GVMd data..."
su -c "greenbone-feed-sync --type GVMD_DATA" gvm
sleep 5

echo "Updating SCAP data..."
su -c "greenbone-feed-sync --type SCAP" gvm
sleep 5

echo "Updating CERT data..."
su -c "greenbone-feed-sync --type CERT" gvm

true

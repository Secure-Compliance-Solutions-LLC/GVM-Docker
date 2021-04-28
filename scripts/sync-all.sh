#!/usr/bin/env bash

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

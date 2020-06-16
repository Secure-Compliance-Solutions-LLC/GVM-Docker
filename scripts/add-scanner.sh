#!/usr/bin/env bash
set -Eeuo pipefail

read -p "Scanner Name: " SCANNER_NAME
read -p "Scanner public key: " SCANNER_KEY

echo "Adding scanner $SCANNER_NAME..."

IFS=' '

read -a $SCANNER_KEY_ARRAY <<< "$text"

su -c "gvmd --create-scanner=$SCANNER_NAME --scanner-type=OpenVAS --scanner-host='/sockets/$SCANNER_KEY_ARRAY[2].sock'" gvm

echo "$SCANNER_KEY\n" >> /data/scanner-ssh-keys/authorized_keys
chown gvm:gvm -R /data/scanner-ssh-keys

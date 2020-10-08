#!/usr/bin/env bash

echo "++++++++++++++++++++++"
echo "+ Run prepare script +"
echo "++++++++++++++++++++++"
./prepare.sh

echo "++++++++++++++++"
echo "+ Tailing logs +"
echo "++++++++++++++++"
tail -F /usr/local/var/log/gvm/*
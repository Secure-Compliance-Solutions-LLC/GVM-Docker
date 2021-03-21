#!/usr/bin/env bash

echo "++++++++++++++++++++++"
echo "+ Run prepare script +"
echo "++++++++++++++++++++++"
./pre-start.sh

echo "++++++++++++++++"
echo "+ Tailing logs +"
echo "++++++++++++++++"
tail -F /usr/local/var/log/gvm/* &

wait $! #Ensures Postgres Shutdowns

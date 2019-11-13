#!/bin/bash

echo "Creating PostgreSQL database for GVM"

createuser -DRS greenbone
createdb -O greenbone gvmd
psql gvmd << EOF
create role dba with superuser noinherit;
grant dba to greenbone;
EOF
psql gvmd << EOF
create extension "uuid-ossp";
EOF

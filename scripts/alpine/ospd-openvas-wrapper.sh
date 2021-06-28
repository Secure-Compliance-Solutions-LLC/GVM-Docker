#!/usr/bin/env bash
set -x

# PreClean up the pid file
if [ -f /var/run/ospd.pid ]; then
  rm -f /var/run/ospd.pid
fi

# SIGTERM-handler
term_handler() {
  if [ -f /var/run/ospd.pid ]; then
    kill "$(cat /var/run/ospd.pid)"
    rm -f /var/run/ospd.pid
  fi
  exit 143 # 128 + 15 -- SIGTERM
}

# setup handlers
# on callback, kill the last background process, which is `tail -f /dev/null` and execute the specified handler
trap 'term_handler' SIGTERM SIGINT

# run application
exec "$@"

#!/usr/bin/env bash
if [ "${SYSTEM_DIST}" == "alpine" ]; then
    exec /usr/sbin/crond -f -l 8 -c /etc/crontabs
elif [ "${SYSTEM_DIST}" == "debian" ]; then
    exec /usr/sbin/cron -f -l -L 8
fi

#!/usr/bin/env bash
if [ "${SYSTEM_DIST}" == "alpine" ]; then
    exec /usr/bin/gvmd "$@"
elif [ "${SYSTEM_DIST}" == "debian" ]; then
    exec /usr/sbin/gvmd "$@"
fi

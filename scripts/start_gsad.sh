#!/usr/bin/env bash
if [ "${SYSTEM_DIST}" == "alpine" ]; then
    exec /usr/bin/gsad "$@"
elif [ "${SYSTEM_DIST}" == "debian" ]; then
    exec /usr/sbin/gsad "$@"
fi

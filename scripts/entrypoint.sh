#!/usr/bin/env bash
set -e
export GVMD_USER=${USERNAME:-${GVMD_USER:-admin}}
export GVMD_PASSWORD=${PASSWORD:-${GVMD_PASSWORD:-adminpassword}}
export GVMD_PASSWORD_FILE=${PASSWORD_FILE:-${GVMD_PASSWORD_FILE:-adminpassword}}
export GVMD_HOST=${GVMD_HOST:-localhost}
export USERNAME=${USERNAME:-${GVMD_USER:-admin}}
export PASSWORD=${PASSWORD:-${GVMD_PASSWORD:-adminpassword}}
export PASSWORD_FILE=${PASSWORD_FILE:-${GVMD_PASSWORD_FILE:-none}}
export TIMEOUT=${TIMEOUT:-15}
export RELAYHOST=${RELAYHOST:-smtp}
export SMTPPORT=${SMTPPORT:-25}
export AUTO_SYNC=${AUTO_SYNC:-true}
export HTTPS=${HTTPS:-true}
export TZ=${TZ:-Etc/UTC}
export DEBUG=${DEBUG:-N}
export SSHD=${SSHD:-false}
export DB_PASSWORD=${DB_PASSWORD:-none}
export DB_PASSWORD_FILE=${DB_PASSWORD_FILE:-none}

if [ "$1" == "/usr/bin/supervisord" ]; then
    echo "Starting Postfix for report delivery by email"
    sed -i "s/^relayhost.*$/relayhost = ${RELAYHOST}:${SMTPPORT}/" /etc/postfix/main.cf
    /usr/sbin/postfix -c /etc/postfix start

    #  exec /start.sh
    echo "GVM Started but with > supervisor <"
    if [ ! -f "/firstrun" ]; then
        echo "Running first start configuration..."

        ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" >/etc/timezone

        touch /firstrun
    fi
fi

exec "$@"

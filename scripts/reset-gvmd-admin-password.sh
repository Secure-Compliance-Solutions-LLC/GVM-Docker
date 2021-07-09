#!/usr/bin/env bash
set -Eeuo pipefail

RESET_USERNAME=${USERNAME:-${GVMD_USER:-admin}}

read -pr "Reset to new password: " RESET_PASSWORD
read -pr "Repeate new password: " RESET_PASSWORD2

if [ "${RESET_PASSWORD}" == "${RESET_PASSWORD2}" ]; then

    su -c "gvmd --user=\"${RESET_USERNAME}\" --new-password=\"${RESET_PASSWORD}\"" gvm

else

    echo "Password did not match - aborted."

fi

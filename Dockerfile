FROM alpine:3

EXPOSE 22 5432 8081 9392

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]

ARG SUPVISD=supervisorctl
ARG GVMD_USER
ARG GVMD_PASSWORD
ARG USERNAME=admin
ARG PASSWORD=adminpassword
ARG TIMEOUT=15
ARG DEBUG=N
ARG RELAYHOST=smtp
ARG SMTPPORT=25
ARG AUTO_SYNC=true
ARG HTTPS=true
ARG TZ=UTC
ARG SSHD=false
ARG DB_PASSWORD=none
ARG SETUP=0

RUN mkdir -p /repo/main \
    && mkdir -p /repo/community

COPY apk-build/target/ /repo/
COPY apk-build/user.abuild/*.pub /etc/apk/keys/

ENV SUPVISD=${SUPVISD:-supervisorctl} \
    USERNAME=${GVMD_USER:-${USERNAME:-admin}} \
    PASSWORD=${GVMD_PASSWORD:-${PASSWORD:-admin}} \
    TIMEOUT=${TIMEOUT:-15} \
    DEBUG=${DEBUG:-N} \
    RELAYHOST=${RELAYHOST:-smtp} \
    SMTPPORT=${SMTPPORT:-25} \
    AUTO_SYNC=${AUTO_SYNC:-true} \
    HTTPS=${HTTPS:-true} \
    TZ=${TZ:-UTC} \
    SSHD=${SSHD:-false} \
    DB_PASSWORD=${DB_PASSWORD:-none}\
    SETUP=${SETUP:-0}

RUN { \
    echo '@custcom /repo/community/'; \
    echo 'https://dl-5.alpinelinux.org/alpine/v3.14/main/' ; \
    echo 'https://dl-5.alpinelinux.org/alpine/v3.14/community/' ;\
    echo 'https://dl-4.alpinelinux.org/alpine/v3.14/main/' ; \
    echo 'https://dl-4.alpinelinux.org/alpine/v3.14/community/' ;\
    echo 'https://dl-cdn.alpinelinux.org/alpine/v3.14/main/' ; \
    echo 'https://dl-cdn.alpinelinux.org/alpine/v3.14/community/' ; \
    } >/etc/apk/repositories \
    && cat /etc/apk/repositories \
    && apk upgrade --no-cache --available \
    && sleep 10 \
    && apk add --no-cache --allow-untrusted curl wget su-exec tzdata postfix mailx bash openssh supervisor openssh-client-common libxslt xmlstarlet zip sshpass socat net-snmp-tools samba-client py3-lxml py3-gvm@custcom openvas@custcom openvas-smb@custcom openvas-config@custcom gvmd@custcom gvm-libs@custcom greenbone-security-assistant@custcom ospd-openvas@custcom \
    && mkdir -p /var/log/supervisor/ \
    && su -c "mkdir /var/lib/gvm/.ssh/ && chmod 700 /var/lib/gvm/.ssh/ && touch /var/lib/gvm/.ssh/authorized_keys && chmod 644 /var/lib/gvm/.ssh/authorized_keys" gvm \
    && apk add --no-cache --allow-untrusted texlive-dvi texlive-xetex xdvik texlive-luatex \
    && apk add --no-cache --allow-untrusted texlive logrotate

COPY gvm-sync-data/gvm-sync-data.tar.xz /opt/gvm-sync-data.tar.xz
COPY scripts/* /
COPY report_formats/* /report_formats/
COPY config/supervisord.conf /etc/supervisord.conf
COPY config/logrotate-gvm.conf /etc/logrotate.d/gvm
COPY config/redis-openvas.conf /etc/redis.conf

VOLUME [ "/opt/database", "/var/lib/openvas/plugins", "/var/lib/gvm", "/etc/ssh" ]

RUN env \
    && if [ "${SETUP}" == "1" ]; then \
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" >/etc/timezone \
    && /usr/bin/supervisord -c /etc/supervisord.conf || true ; \
    unset SETUP ;\
    fi \
    && rm -rf /var/lib/gvm/CA || true \
    && rm -rf /var/lib/gvm/private || true \
    && rm /etc/localtime || true\
    && echo "UTC" >/etc/timezone \
    && rm -rf /tmp/* /var/cache/apk/* \
    && echo "!!! FINISH Setup !!!"
ENV SETUP=0
#
#   Owned by User gvm
#
#       /run/ospd
#       /var/lib/openvas/plugins
#       /var/lib/gvm
#       /var/lib/gvm/gvmd
#       /var/lib/gvm/gvmd/gnupg
#       /var/log/gvm
#
#   Owned by Group gvm
#
#       /run/ospd
#       /var/lib/gvm
#       /var/lib/gvm/gvmd
#       /var/lib/gvm/gvmd/gnupg
#
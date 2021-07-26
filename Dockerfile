FROM alpine:3

EXPOSE 22 5432 8081 9392

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]

ARG SUPVISD=supervisorctl
ARG GVMD_USER
ARG GVMD_PASSWORD
ARG USERNAME=admin
ARG PASSWORD=adminpassword
ARG PASSWORD_FILE=none
ARG TIMEOUT=15
ARG DEBUG=N
ARG RELAYHOST=smtp
ARG SMTPPORT=25
ARG AUTO_SYNC=true
ARG CERTIFICATE=none
ARG CERTIFICATE_KEY=none
ARG HTTPS=true
ARG TZ=Etc/UTC
ARG SSHD=false
ARG DB_PASSWORD=none

RUN mkdir -p /repo/main \
    && mkdir -p /repo/community

COPY apk-build/target/ /repo/
COPY apk-build/user.abuild/*.pub /etc/apk/keys/

ENV SUPVISD=${SUPVISD:-supervisorctl} \
    USERNAME=${USERNAME:-${GVMD_USER:-admin}} \
    PASSWORD=${PASSWORD:-${GVMD_PASSWORD:-admin}} \
    PASSWORD_FILE=${PASSWORD_FILE:-${GVMD_PASSWORD_FILE:-none}} \
    TIMEOUT=${TIMEOUT:-15} \
    DEBUG=${DEBUG:-N} \
    RELAYHOST=${RELAYHOST:-smtp} \
    SMTPPORT=${SMTPPORT:-25} \
    AUTO_SYNC=${AUTO_SYNC:-true} \
    HTTPS=${HTTPS:-true} \
    CERTIFICATE=${CERTIFICATE:-none} \
    CERTIFICATE_KEY=${CERTIFICATE_KEY:-none} \
    TZ=${TZ:-Etc/UTC} \
    SSHD=${SSHD:-false} \
    DB_PASSWORD=${DB_PASSWORD:-none} \
    DB_PASSWORD_FILE=${DB_PASSWORD:-none} \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

ENV MUSL_LOCPATH="/usr/share/i18n/locales/musl"

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
    # install libintl
    # then install dev dependencies for musl-locales
    # clone the sources
    # build and install musl-locales
    # remove sources and compile artifacts
    # lastly remove dev dependencies again
    && apk --no-cache add libintl \
    && apk --no-cache --virtual .locale_build add cmake make musl-dev gcc gettext-dev git \
    && git clone https://gitlab.com/rilian-la-te/musl-locales \
    && cd musl-locales && cmake -DLOCALE_PROFILE=OFF -DCMAKE_INSTALL_PREFIX:PATH=/usr . && make && make install \
    && cd .. && rm -r musl-locales \
    && apk del --no-cache .locale_build \
    && sleep 10 \
    && apk add --no-cache --allow-untrusted logrotate curl wget su-exec tzdata postfix mailx bash openssh supervisor openssh-client-common libxslt xmlstarlet zip sshpass socat net-snmp-tools samba-client py3-lxml py3-gvm@custcom openvas@custcom openvas-smb@custcom openvas-config@custcom gvmd@custcom gvm-libs@custcom greenbone-security-assistant@custcom ospd-openvas@custcom \
    && mkdir -p /var/log/supervisor/ \
    && su -c "mkdir /var/lib/gvm/.ssh/ && chmod 700 /var/lib/gvm/.ssh/ && touch /var/lib/gvm/.ssh/authorized_keys && chmod 644 /var/lib/gvm/.ssh/authorized_keys" gvm 

COPY gvm-sync-data/gvm-sync-data.tar.xz /opt/gvm-sync-data.tar.xz
COPY scripts/* /
COPY report_formats/* /report_formats/
COPY config/supervisord.conf /etc/supervisord.conf
COPY config/logrotate-gvm.conf /etc/logrotate.d/gvm
COPY config/redis-openvas.conf /etc/redis.conf
COPY ./sshd_config /etc/ssh/sshd_config


ARG SETUP=0
ARG OPT_PDF=0
ENV SETUP=${SETUP:-0} \
    OPT_PDF=${OPT_PDF:-0}

RUN env \
    && if [ "${SETUP}" == "1" ]; then \
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" >/etc/timezone \
    && /usr/bin/supervisord -c /etc/supervisord.conf || true ; \
    unset SETUP ;\
    fi \
    && rm -rfv /var/lib/gvm/CA || true \
    && rm -rfv /var/lib/gvm/private || true \
    && rm /etc/localtime || true\
    && echo "Etc/UTC" >/etc/timezone \
    && rm -rfv /tmp/* /var/cache/apk/* \
    && echo "!!! FINISH Setup !!!"
ENV SETUP=0

# Addons
RUN if [ "${OPT_PDF}" == "1" ]; then apk add --no-cache --allow-untrusted texlive texmf-dist-latexextra texmf-dist-fontsextra ; fi 

VOLUME [ "/opt/database", "/var/lib/openvas/plugins", "/var/lib/gvm", "/etc/ssh" ]

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
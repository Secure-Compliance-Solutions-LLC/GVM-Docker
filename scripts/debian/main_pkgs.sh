#!/usr/bin/env bash
set -Eeuxo pipefail

apt-get -qq update
apt-get -yq upgrade

#export PATH=$PATH:/usr/local/sbin
export INSTALL_PREFIX=/usr

export SOURCE_DIR=$HOME/source
mkdir -p "${SOURCE_DIR}"

export BUILD_DIR=$HOME/build
mkdir -p "${BUILD_DIR}"

export INSTALL_DIR=$HOME/install
mkdir -p "${INSTALL_DIR}"

export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:${PKG_CONFIG_PATH:-}"

sudo apt-get install --no-install-recommends --assume-yes \
    build-essential \
    curl \
    cmake \
    pkg-config \
    python3 \
    python3-dev \
    python3-pip \
    gnupg \
    supervisor

curl -sf -L https://www.greenbone.net/GBCommunitySigningKey.asc -o /tmp/GBCommunitySigningKey.asc

export GNUPGHOME=/tmp/openvas-gnupg
mkdir -p $GNUPGHOME

gpg --import /tmp/GBCommunitySigningKey.asc
echo "8AE4BE429B60A59B311C2E739823FAA60ED1E580:6:" | gpg --import-ownertrust

sudo mkdir -p $OPENVAS_GNUPG_HOME
sudo cp -r /tmp/openvas-gnupg/* $OPENVAS_GNUPG_HOME/
sudo chown -R gvm:gvm $OPENVAS_GNUPG_HOME

# Install required dependencies for gvm-libs
sudo apt-get install -y --no-install-recommends \
    libglib2.0-dev \
    graphviz graphviz-dev \
    libgpgme-dev \
    libgpgme11 \
    libgnutls28-dev \
    uuid-dev \
    libssh-gcrypt-dev \
    libssh-gcrypt-4 \
    libhiredis-dev \
    libhiredis0.14 \
    libxml2-dev \
    libpcap-dev \
    libnet1-dev \
    libnet1 \
    libpaho-mqtt-dev \
    libpaho-mqtt1.3 \
    libbsd-dev

# Install optional dependencies for gvm-libs
sudo apt-get install -y --no-install-recommends \
    libldap2-dev \
    libradcli-dev \
    libradcli4

# Download and install gvm-libs
curl -fsSL "https://github.com/greenbone/gvm-libs/archive/refs/tags/v${gvm_libs_version}.tar.gz" -o "${SOURCE_DIR}/gvm-libs-${gvm_libs_version}.tar.gz"
curl -fsSL "https://github.com/greenbone/gvm-libs/releases/download/v${gvm_libs_version}/gvm-libs-v${gvm_libs_version}.tar.gz.asc" -o "${SOURCE_DIR}/gvm-libs-${gvm_libs_version}.tar.gz.asc"

ls -lahr "${SOURCE_DIR}"

# Verify the signature of the gvm-libs tarball
gpg --verify "${SOURCE_DIR}/gvm-libs-${gvm_libs_version}.tar.gz.asc" "${SOURCE_DIR}/gvm-libs-${gvm_libs_version}.tar.gz"

# Unpack the gvm-libs tarball
tar -C "${SOURCE_DIR}" -xvzf "${SOURCE_DIR}/gvm-libs-${gvm_libs_version}.tar.gz"

# Build and install gvm-libs

mkdir -p "${BUILD_DIR}/gvm-libs" && cd "${BUILD_DIR}/gvm-libs"

cmake "${SOURCE_DIR}/gvm-libs-${gvm_libs_version}" \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
    -DCMAKE_BUILD_TYPE=Release \
    -DSYSCONFDIR=/etc \
    -DLOCALSTATEDIR=/var \
    -DGVM_PID_DIR=/run/gvm

make "-j$(nproc)"

make DESTDIR="${INSTALL_DIR}"/gvm-libs install
sudo cp -rv ${INSTALL_DIR}/gvm-libs/* /
#rm -rf ${INSTALL_DIR}/*

# Install required dependencies for gvmd
sudo apt-get install -y --no-install-recommends \
    libglib2.0-dev \
    libgnutls28-dev \
    libpq-dev \
    postgresql-server-dev-15 \
    libical-dev \
    libical3 \
    libgpgme-dev \
    xsltproc \
    rsync

# Install optional dependencies for gvmd
sudo apt-get install -y --no-install-recommends \
    xmlstarlet \
    zip \
    rpm \
    fakeroot \
    dpkg \
    nsis \
    gnupg \
    gpgsm \
    wget \
    sshpass \
    openssh-client \
    socat \
    snmp \
    python3 \
    smbclient \
    python3-lxml \
    gnutls-bin \
    xml-twig-tools

# Download and install gvmd
curl -fsSL https://github.com/greenbone/gvmd/archive/refs/tags/v${gvmd_version}.tar.gz -o ${SOURCE_DIR}/gvmd-${gvmd_version}.tar.gz
curl -fsSL https://github.com/greenbone/gvmd/releases/download/v${gvmd_version}/gvmd-${gvmd_version}.tar.gz.asc -o ${SOURCE_DIR}/gvmd-${gvmd_version}.tar.gz.asc

gpg --verify ${SOURCE_DIR}/gvmd-${gvmd_version}.tar.gz.asc ${SOURCE_DIR}/gvmd-${gvmd_version}.tar.gz

tar -C ${SOURCE_DIR} -xvzf ${SOURCE_DIR}/gvmd-${gvmd_version}.tar.gz

mkdir -p ${BUILD_DIR}/gvmd && cd ${BUILD_DIR}/gvmd

cmake ${SOURCE_DIR}/gvmd-${gvmd_version} \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
    -DCMAKE_BUILD_TYPE=Release \
    -DLOCALSTATEDIR=/var \
    -DSYSCONFDIR=/etc \
    -DGVM_DATA_DIR=/var \
    -DGVM_RUN_DIR=/run/gvm \
    -DOPENVAS_DEFAULT_SOCKET=/run/ospd/ospd-openvas.sock \
    -DGVM_FEED_LOCK_PATH=/var/lib/gvm/feed-update.lock \
    -DSYSTEMD_SERVICE_DIR=/lib/systemd/system \
    -DLOGROTATE_DIR=/etc/logrotate.d

make -j$(nproc)

make DESTDIR=${INSTALL_DIR}/gvmd install
mv ${INSTALL_DIR}/gvmd/lib/* ${INSTALL_DIR}/gvmd/usr/lib/
rmdir ${INSTALL_DIR}/gvmd/lib
sudo cp -rv ${INSTALL_DIR}/gvmd/* /
#rm -rf ${INSTALL_DIR}/*

# pg-gvm
curl -fsSL https://github.com/greenbone/pg-gvm/archive/refs/tags/v${pg_gvm_version}.tar.gz -o ${SOURCE_DIR}/pg-gvm-${pg_gvm_version}.tar.gz
curl -fsSL https://github.com/greenbone/pg-gvm/releases/download/v${pg_gvm_version}/pg-gvm-${pg_gvm_version}.tar.gz.asc -o ${SOURCE_DIR}/pg-gvm-${pg_gvm_version}.tar.gz.asc

gpg --verify ${SOURCE_DIR}/pg-gvm-${pg_gvm_version}.tar.gz.asc ${SOURCE_DIR}/pg-gvm-${pg_gvm_version}.tar.gz

tar -C ${SOURCE_DIR} -xvzf ${SOURCE_DIR}/pg-gvm-${pg_gvm_version}.tar.gz

mkdir -p ${BUILD_DIR}/pg-gvm && cd ${BUILD_DIR}/pg-gvm

cmake ${SOURCE_DIR}/pg-gvm-${pg_gvm_version} \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
    -DCMAKE_BUILD_TYPE=Release

make DESTDIR=${INSTALL_DIR}/pg-gvm install
sudo cp -rv ${INSTALL_DIR}/pg-gvm/* /

# Install required dependencies for gsad & gsa
sudo apt-get install -y --no-install-recommends \
    libmicrohttpd-dev \
    libmicrohttpd12 \
    libxml2-dev \
    libglib2.0-dev \
    libgnutls28-dev

curl -fsSL https://github.com/greenbone/gsa/archive/refs/tags/v${gsa_version}.tar.gz -o ${SOURCE_DIR}/gsa-${gsa_version}.tar.gz
curl -fsSL https://github.com/greenbone/gsa/releases/download/v${gsa_version}/gsa-${gsa_version}.tar.gz.asc -o ${SOURCE_DIR}/gsa-${gsa_version}.tar.gz.asc
gpg --verify ${SOURCE_DIR}/gsa-${gsa_version}.tar.gz.asc ${SOURCE_DIR}/gsa-${gsa_version}.tar.gz
tar -C ${SOURCE_DIR} -xvzf ${SOURCE_DIR}/gsa-${gsa_version}.tar.gz

curl -fsSL https://github.com/greenbone/gsad/archive/refs/tags/v${gsa_version}.tar.gz -o ${SOURCE_DIR}/gsad-${gsa_version}.tar.gz
curl -fsSL https://github.com/greenbone/gsad/releases/download/v${gsa_version}/gsad-${gsa_version}.tar.gz.asc -o ${SOURCE_DIR}/gsad-${gsa_version}.tar.gz.asc
gpg --verify ${SOURCE_DIR}/gsad-${gsa_version}.tar.gz.asc ${SOURCE_DIR}/gsad-${gsa_version}.tar.gz
tar -C ${SOURCE_DIR} -xvzf ${SOURCE_DIR}/gsad-${gsa_version}.tar.gz

mkdir -p ${BUILD_DIR}/gsad && cd ${BUILD_DIR}/gsad

cmake ${SOURCE_DIR}/gsad-${gsa_version} \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
    -DCMAKE_BUILD_TYPE=Release \
    -DSYSCONFDIR=/etc \
    -DLOCALSTATEDIR=/var \
    -DGSAD_RUN_DIR=/run/gvm \
    -DLOGROTATE_DIR=/etc/logrotate.d

make -j$(nproc)

make DESTDIR=${INSTALL_DIR}/gsad install
mv ${INSTALL_DIR}/gsad/lib/* ${INSTALL_DIR}/gsad/usr/lib/
rmdir ${INSTALL_DIR}/gsad/lib
sudo cp -rv ${INSTALL_DIR}/gsad/* /

pushd ${SOURCE_DIR}/gsa-${gsa_version}
rm -fr ./build

yarn
yarn build

mkdir -p $INSTALL_PREFIX/share/gvm/gsad/web/
mv build/* $INSTALL_PREFIX/share/gvm/gsad/web/

popd

# Install required dependencies for openvas-smb
sudo apt-get install -y --no-install-recommends \
    gcc-mingw-w64 \
    libgnutls28-dev \
    libglib2.0-dev \
    libpopt-dev \
    libunistring-dev \
    heimdal-dev \
    libgssapi3-heimdal \
    libhdb9-heimdal \
    perl-base

curl -fsSL https://github.com/greenbone/openvas-smb/archive/refs/tags/v${openvas_smb_version}.tar.gz -o ${SOURCE_DIR}/openvas-smb-${openvas_smb_version}.tar.gz
curl -fsSL https://github.com/greenbone/openvas-smb/releases/download/v${openvas_smb_version}/openvas-smb-v${openvas_smb_version}.tar.gz.asc -o ${SOURCE_DIR}/openvas-smb-${openvas_smb_version}.tar.gz.asc
gpg --verify ${SOURCE_DIR}/openvas-smb-${openvas_smb_version}.tar.gz.asc ${SOURCE_DIR}/openvas-smb-${openvas_smb_version}.tar.gz

tar -C ${SOURCE_DIR} -xvzf ${SOURCE_DIR}/openvas-smb-${openvas_smb_version}.tar.gz

mkdir -p ${BUILD_DIR}/openvas-smb && cd ${BUILD_DIR}/openvas-smb

cmake ${SOURCE_DIR}/openvas-smb-${openvas_smb_version} \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
    -DCMAKE_BUILD_TYPE=Release

make -j$(nproc)
make DESTDIR=${INSTALL_DIR}/openvas-smb install
sudo cp -rv ${INSTALL_DIR}/openvas-smb/* /
#rm -rf ${INSTALL_DIR}/*

# Install required dependencies for openvas-scanner
sudo apt-get install -y --no-install-recommends \
  bison \
  libglib2.0-dev \
  libgnutls28-dev \
  libgcrypt20-dev \
  libpcap-dev \
  libgpgme-dev \
  libksba-dev \
  rsync \
  nmap \
  libjson-glib-1.0-0 \
  libjson-glib-dev \
  libglib2.0-bin \
  libglib2.0-dev

# Install optional dependencies for openvas-scanner
sudo apt-get install -y \
    python3-impacket \
    libsnmp-dev

curl -fsSL https://github.com/greenbone/openvas-scanner/archive/refs/tags/v${openvas_scanner_version}.tar.gz -o ${SOURCE_DIR}/openvas-scanner-${openvas_scanner_version}.tar.gz
curl -fsSL https://github.com/greenbone/openvas-scanner/releases/download/v${openvas_scanner_version}/openvas-scanner-v${openvas_scanner_version}.tar.gz.asc -o ${SOURCE_DIR}/openvas-scanner-${openvas_scanner_version}.tar.gz.asc
gpg --verify ${SOURCE_DIR}/openvas-scanner-${openvas_scanner_version}.tar.gz.asc ${SOURCE_DIR}/openvas-scanner-${openvas_scanner_version}.tar.gz

tar -C ${SOURCE_DIR} -xvzf ${SOURCE_DIR}/openvas-scanner-${openvas_scanner_version}.tar.gz

mkdir -p ${BUILD_DIR}/openvas-scanner && cd ${BUILD_DIR}/openvas-scanner

cmake ${SOURCE_DIR}/openvas-scanner-${openvas_scanner_version} \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
    -DCMAKE_BUILD_TYPE=Release \
    -DINSTALL_OLD_SYNC_SCRIPT=OFF \
    -DSYSCONFDIR=/etc \
    -DLOCALSTATEDIR=/var \
    -DOPENVAS_FEED_LOCK_PATH=/var/lib/openvas/feed-update.lock \
    -DOPENVAS_RUN_DIR=/run/ospd

make -j$(nproc)
make DESTDIR=${INSTALL_DIR}/openvas-scanner install
sudo cp -rv ${INSTALL_DIR}/openvas-scanner/* /
#rm -rf ${INSTALL_DIR}/*

# Install required dependencies for ospd-openvas
sudo apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-packaging \
    python3-wrapt \
    python3-cffi \
    python3-psutil \
    python3-lxml \
    python3-defusedxml \
    python3-paramiko \
    python3-redis \
    python3-gnupg \
    python3-paho-mqtt \
    libnet1

#sudo python3 -m pip install --no-warn-script-location psutil

# Download and install ospd-openvas
curl -fsSL https://github.com/greenbone/ospd-openvas/archive/refs/tags/v${ospd_openvas}.tar.gz -o ${SOURCE_DIR}/ospd-openvas-${ospd_openvas}.tar.gz
curl -fsSL https://github.com/greenbone/ospd-openvas/releases/download/v${ospd_openvas}/ospd-openvas-v${ospd_openvas}.tar.gz.asc -o ${SOURCE_DIR}/ospd-openvas-${ospd_openvas}.tar.gz.asc
gpg --verify ${SOURCE_DIR}/ospd-openvas-${ospd_openvas}.tar.gz.asc ${SOURCE_DIR}/ospd-openvas-${ospd_openvas}.tar.gz

tar -C ${SOURCE_DIR} -xvzf ${SOURCE_DIR}/ospd-openvas-${ospd_openvas}.tar.gz

cd ${SOURCE_DIR}/ospd-openvas-${ospd_openvas}
mkdir -p $INSTALL_DIR/ospd-openvas
python3 -m pip install --root=$INSTALL_DIR/ospd-openvas --no-warn-script-location .
sudo cp -rv ${INSTALL_DIR}/ospd-openvas/* /
#rm -rf ${INSTALL_DIR}/*

# notus-scanner
sudo apt-get install -y \
  python3 \
  python3-pip \
  python3-setuptools \
  python3-paho-mqtt \
  python3-psutil \
  python3-gnupg

curl -f -L https://github.com/greenbone/notus-scanner/archive/refs/tags/v$NOTUS_VERSION.tar.gz -o $SOURCE_DIR/notus-scanner-$NOTUS_VERSION.tar.gz
curl -f -L https://github.com/greenbone/notus-scanner/releases/download/v$NOTUS_VERSION/notus-scanner-v$NOTUS_VERSION.tar.gz.asc -o $SOURCE_DIR/notus-scanner-$NOTUS_VERSION.tar.gz.asc

gpg --verify $SOURCE_DIR/notus-scanner-$NOTUS_VERSION.tar.gz.asc $SOURCE_DIR/notus-scanner-$NOTUS_VERSION.tar.gz
tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/notus-scanner-$NOTUS_VERSION.tar.gz

cd $SOURCE_DIR/notus-scanner-$NOTUS_VERSION
mkdir -p $INSTALL_DIR/notus-scanner
python3 -m pip install --root=$INSTALL_DIR/notus-scanner --no-warn-script-location .
sudo cp -rv $INSTALL_DIR/notus-scanner/* /

# greenbone-feed-sync
sudo apt-get install -y \
  python3 \
  python3-pip

mkdir -p $INSTALL_DIR/greenbone-feed-sync
python3 -m pip install --root=$INSTALL_DIR/greenbone-feed-sync --no-warn-script-location greenbone-feed-sync
sudo cp -rv $INSTALL_DIR/greenbone-feed-sync/* /

# Install required dependencies for gvmd-tools
sudo apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-packaging \
    python3-lxml \
    python3-defusedxml \
    python3-paramiko
# Install for user
# python3 -m pip install --user gvm-tools

# Install for root
mkdir -p $INSTALL_DIR/gvm-tools
python3 -m pip install --root=$INSTALL_DIR/gvm-tools --no-warn-script-location gvm-tools
sudo cp -rv ${INSTALL_DIR}/gvm-tools/* /
#rm -rf ${INSTALL_DIR}/*

# Install redis-server
sudo apt-get install -y --no-install-recommends redis-server
sudo mkdir -p /etc/redis
sudo cp ${SOURCE_DIR}/openvas-scanner-${openvas_scanner_version}/config/redis-openvas.conf /etc/redis/redis-openvas.conf
sudo chown redis:redis /etc/redis/*.conf
echo "db_address = /run/redis-openvas/redis.sock" | sudo tee -a /etc/openvas/openvas.conf

sudo usermod -aG redis gvm

# setup of mosquitto
echo -e "mqtt_server_uri = localhost:1883\ntable_driven_lsc = yes" | sudo tee -a /etc/openvas/openvas.conf

# Adjusting the permissions
sudo mkdir -p /var/lib/notus
sudo chown -R gvm:gvm /var/lib/notus
sudo chown -R gvm:gvm /var/lib/gvm
sudo chown -R gvm:gvm /var/lib/openvas
sudo chown -R gvm:gvm /var/log/gvm
sudo chown -R gvm:gvm /run/gvm

sudo chmod -R g+srw /var/lib/gvm
sudo chmod -R g+srw /var/lib/openvas
sudo chmod -R g+srw /var/log/gvm

sudo chown gvm:gvm /usr/sbin/gvmd
sudo chmod 6750 /usr/sbin/gvmd


# SUDO for Scanning
echo '%gvm ALL = NOPASSWD: /usr/sbin/openvas' | sudo EDITOR='tee -a' visudo

# Install Postgres
sudo apt-get install -y --no-install-recommends postgresql

# Remove required dependencies for gvm-libs
sudo apt-get purge --auto-remove -y \
    heimdal-dev \
    libgcrypt20-dev \
    libglib2.0-dev \
    libgnutls28-dev \
    libgpgme-dev \
    libhiredis-dev \
    libksba-dev \
    libldap2-dev \
    libmicrohttpd-dev \
    libnet1-dev \
    libpcap-dev \
    libpopt-dev \
    libradcli-dev \
    libsnmp-dev \
    libssh-gcrypt-dev \
    libunistring-dev \
    libxml2-dev \
    uuid-dev \
    python3-dev \
    build-essential \
    postgresql-server-dev-all \
    yarn \
    graphviz-dev \
    cmake
sudo apt-get purge --auto-remove -y *-dev

sudo apt-get -y autoremove
sudo apt-get -y clean

echo "/usr/lib64
/usr/lib" >/etc/ld.so.conf.d/openvas.conf && ldconfig

rm -rf ${SOURCE_DIR} ${BUILD_DIR} ${INSTALL_DIR}
rm -rf /var/lib/apt/lists/*
rm -f /etc/apt/apt.conf.d/30proxy

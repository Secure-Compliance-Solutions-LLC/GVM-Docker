#!/usr/bin/env bash
set -Eeuo pipefail

apt-get update
apt-get -yq upgrade

#export PATH=$PATH:/usr/local/sbin
export INSTALL_PREFIX=/usr

export SOURCE_DIR=$HOME/source
mkdir -p "${SOURCE_DIR}"

export BUILD_DIR=$HOME/build
mkdir -p "${BUILD_DIR}"

export INSTALL_DIR=$HOME/install
mkdir -p "${INSTALL_DIR}"

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
sudo python3 -m pip install --upgrade pip

curl -O https://www.greenbone.net/GBCommunitySigningKey.asc
gpg --import <GBCommunitySigningKey.asc
(
    echo 5
    echo y
    echo save
) | gpg --command-fd 0 --no-tty --no-greeting -q --edit-key "$(gpg --list-packets <GBCommunitySigningKey.asc | awk '$1=="keyid:"{print$2;exit}')" trust

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
    libnet1

# Install optional dependencies for gvm-libs
sudo apt-get install -y --no-install-recommends \
    libldap2-dev \
    libradcli-dev \
    libradcli4

# Download and install gvm-libs
curl -sSL "https://github.com/greenbone/gvm-libs/archive/refs/tags/v${gvm_libs_version}.tar.gz" -o "${SOURCE_DIR}/gvm-libs-${gvm_libs_version}.tar.gz"
curl -sSL "https://github.com/greenbone/gvm-libs/releases/download/v${gvm_libs_version}/gvm-libs-${gvm_libs_version}.tar.gz.asc" -o "${SOURCE_DIR}/gvm-libs-${gvm_libs_version}.tar.gz.asc"

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

make DESTDIR="${INSTALL_DIR}" install
sudo cp -rv ${INSTALL_DIR}/* /
#rm -rf ${INSTALL_DIR}/*

# Install required dependencies for gvmd
sudo apt-get install -y --no-install-recommends \
    libglib2.0-dev \
    libgnutls28-dev \
    libpq-dev \
    postgresql-server-dev-all \
    libical-dev \
    libical3 \
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
curl -sSL https://github.com/greenbone/gvmd/archive/refs/tags/v${gvmd_version}.tar.gz -o ${SOURCE_DIR}/gvmd-${gvmd_version}.tar.gz
curl -sSL https://github.com/greenbone/gvmd/releases/download/v${gvmd_version}/gvmd-${gvmd_version}.tar.gz.asc -o ${SOURCE_DIR}/gvmd-${gvmd_version}.tar.gz.asc

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
    -DPostgreSQL_TYPE_INCLUDE_DIR=/usr/include/postgresql \
    -DOPENVAS_DEFAULT_SOCKET=/run/ospd/ospd-openvas.sock \
    -DGVM_FEED_LOCK_PATH=/var/lib/gvm/feed-update.lock \
    -DSYSTEMD_SERVICE_DIR=/lib/systemd/system \
    -DDEFAULT_CONFIG_DIR=/etc/default \
    -DLOGROTATE_DIR=/etc/logrotate.d

make -j$(nproc)

make DESTDIR=${INSTALL_DIR} install
sudo cp -rv ${INSTALL_DIR}/* /
#rm -rf ${INSTALL_DIR}/*

# Install required dependencies for gsad & gsa
sudo apt-get install -y --no-install-recommends \
    libmicrohttpd-dev \
    libmicrohttpd12 \
    libxml2-dev \
    libglib2.0-dev \
    libgnutls28-dev

sudo apt-get install -y --no-install-recommends \
    nodejs \
    yarnpkg

# looks like need because of an issue with yarn
yarnpkg install
yarnpkg upgrade

curl -sSL https://github.com/greenbone/gsa/archive/refs/tags/v${gsa_version}.tar.gz -o ${SOURCE_DIR}/gsa-${gsa_version}.tar.gz
curl -sSL https://github.com/greenbone/gsa/releases/download/v${gsa_version}/gsa-${gsa_version}.tar.gz.asc -o ${SOURCE_DIR}/gsa-${gsa_version}.tar.gz.asc
gpg --verify ${SOURCE_DIR}/gsa-${gsa_version}.tar.gz.asc ${SOURCE_DIR}/gsa-${gsa_version}.tar.gz
tar -C ${SOURCE_DIR} -xvzf ${SOURCE_DIR}/gsa-${gsa_version}.tar.gz

#curl -sSL https://github.com/greenbone/gsa/releases/download/v${gsa_version}/gsa-node-modules-${gsa_version}.tar.gz -o ${SOURCE_DIR}/gsa-node-modules-${gsa_version}.tar.gz
#curl -sSL https://github.com/greenbone/gsa/releases/download/v${gsa_version}/gsa-node-modules-${gsa_version}.tar.gz.asc -o ${SOURCE_DIR}/gsa-node-modules-${gsa_version}.tar.gz.asc
#gpg --verify ${SOURCE_DIR}/gsa-node-modules-${gsa_version}.tar.gz.asc ${SOURCE_DIR}/gsa-node-modules-${gsa_version}.tar.gz
#tar -C ${SOURCE_DIR}/gsa-${gsa_version}/gsa -xvzf ${SOURCE_DIR}/gsa-node-modules-${gsa_version}.tar.gz

mkdir -p ${BUILD_DIR}/gsa && cd ${BUILD_DIR}/gsa

yarnpkg install

cmake ${SOURCE_DIR}/gsa-${gsa_version} \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
    -DCMAKE_BUILD_TYPE=Release \
    -DSYSCONFDIR=/etc \
    -DLOCALSTATEDIR=/var \
    -DGVM_RUN_DIR=/run/gvm \
    -DGSAD_PID_DIR=/run/gvm \
    -DLOGROTATE_DIR=/etc/logrotate.d

make -j$(nproc)

make DESTDIR=${INSTALL_DIR} install
sudo cp -rv ${INSTALL_DIR}/* /
#rm -rf ${INSTALL_DIR}/*

sudo apt-get purge -y \
    nodejs \
    yarnpkg

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

curl -sSL https://github.com/greenbone/openvas-smb/archive/refs/tags/v${openvas_smb_version}.tar.gz -o ${SOURCE_DIR}/openvas-smb-${openvas_smb_version}.tar.gz
curl -sSL https://github.com/greenbone/openvas-smb/releases/download/v${openvas_smb_version}/openvas-smb-${openvas_smb_version}.tar.gz.asc -o ${SOURCE_DIR}/openvas-smb-${openvas_smb_version}.tar.gz.asc

gpg --verify ${SOURCE_DIR}/openvas-smb-${openvas_smb_version}.tar.gz.asc ${SOURCE_DIR}/openvas-smb-${openvas_smb_version}.tar.gz

tar -C ${SOURCE_DIR} -xvzf ${SOURCE_DIR}/openvas-smb-${openvas_smb_version}.tar.gz

mkdir -p ${BUILD_DIR}/openvas-smb && cd ${BUILD_DIR}/openvas-smb

cmake ${SOURCE_DIR}/openvas-smb-${openvas_smb_version} \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
    -DCMAKE_BUILD_TYPE=Release

make -j$(nproc)
make DESTDIR=${INSTALL_DIR} install
sudo cp -rv ${INSTALL_DIR}/* /
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
    nmap

# Install optional dependencies for openvas-scanner
sudo apt-get install -y \
    python-impacket \
    libsnmp-dev

curl -sSL https://github.com/greenbone/openvas-scanner/archive/refs/tags/v${openvas_scanner_version}.tar.gz -o ${SOURCE_DIR}/openvas-scanner-${openvas_scanner_version}.tar.gz
curl -sSL https://github.com/greenbone/openvas-scanner/releases/download/v${openvas_scanner_version}/openvas-scanner-${openvas_scanner_version}.tar.gz.asc -o ${SOURCE_DIR}/openvas-scanner-${openvas_scanner_version}.tar.gz.asc
gpg --verify ${SOURCE_DIR}/openvas-scanner-${openvas_scanner_version}.tar.gz.asc ${SOURCE_DIR}/openvas-scanner-${openvas_scanner_version}.tar.gz

tar -C ${SOURCE_DIR} -xvzf ${SOURCE_DIR}/openvas-scanner-${openvas_scanner_version}.tar.gz

mkdir -p ${BUILD_DIR}/openvas-scanner && cd ${BUILD_DIR}/openvas-scanner

cmake ${SOURCE_DIR}/openvas-scanner-${openvas_scanner_version} \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
    -DCMAKE_BUILD_TYPE=Release \
    -DSYSCONFDIR=/etc \
    -DLOCALSTATEDIR=/var \
    -DOPENVAS_FEED_LOCK_PATH=/var/lib/openvas/feed-update.lock \
    -DOPENVAS_RUN_DIR=/run/ospd

make -j$(nproc)
make DESTDIR=${INSTALL_DIR} install
sudo cp -rv ${INSTALL_DIR}/* /
#rm -rf ${INSTALL_DIR}/*

# Install required dependencies for ospd-openvas
sudo apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-packaging \
    python3-wrapt \
    python3-cffi \
    python3-psutil/buster-backports \
    python3-lxml \
    python3-defusedxml \
    python3-paramiko \
    python3-redis \
    libnet1

sudo python3 -m pip install --upgrade setuptools

#sudo python3 -m pip install --no-warn-script-location psutil

# Download and install ospd-openvas
curl -sSL https://github.com/greenbone/ospd/archive/refs/tags/v${open_scanner_protocol_daemon}.tar.gz -o ${SOURCE_DIR}/ospd-${open_scanner_protocol_daemon}.tar.gz
curl -sSL https://github.com/greenbone/ospd/releases/download/v${open_scanner_protocol_daemon}/ospd-${open_scanner_protocol_daemon}.tar.gz.asc -o ${SOURCE_DIR}/ospd-${open_scanner_protocol_daemon}.tar.gz.asc
gpg --verify ${SOURCE_DIR}/ospd-${open_scanner_protocol_daemon}.tar.gz.asc ${SOURCE_DIR}/ospd-${open_scanner_protocol_daemon}.tar.gz

curl -sSL https://github.com/greenbone/ospd-openvas/archive/refs/tags/v${ospd_openvas}.tar.gz -o ${SOURCE_DIR}/ospd-openvas-${ospd_openvas}.tar.gz
curl -sSL https://github.com/greenbone/ospd-openvas/releases/download/v${ospd_openvas}/ospd-openvas-${ospd_openvas}.tar.gz.asc -o ${SOURCE_DIR}/ospd-openvas-${ospd_openvas}.tar.gz.asc
gpg --verify ${SOURCE_DIR}/ospd-openvas-${ospd_openvas}.tar.gz.asc ${SOURCE_DIR}/ospd-openvas-${ospd_openvas}.tar.gz

tar -C ${SOURCE_DIR} -xvzf ${SOURCE_DIR}/ospd-${open_scanner_protocol_daemon}.tar.gz
tar -C ${SOURCE_DIR} -xvzf ${SOURCE_DIR}/ospd-openvas-${ospd_openvas}.tar.gz

cd ${SOURCE_DIR}/ospd-${open_scanner_protocol_daemon}
python3 -m pip install . --prefix=${INSTALL_PREFIX} --root=${INSTALL_DIR}
python3 -m pip install .

cd ${SOURCE_DIR}/ospd-openvas-${ospd_openvas}
python3 -m pip install . --prefix=${INSTALL_PREFIX} --root=${INSTALL_DIR} --no-warn-script-location
python3 -m pip install . --no-warn-script-location
sudo cp -rv ${INSTALL_DIR}/* /
#rm -rf ${INSTALL_DIR}/*

# Install required dependencies for gvmd-tools
sudo apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-packaging \
    python3-lxml \
    python3-defusedxml \
    python3-paramiko
sudo python3 -m pip install --upgrade setuptools
# Install for user
# python3 -m pip install --user gvm-tools

# Install for root
python3 -m pip install --no-warn-script-location gvm-tools
python3 -m pip install --prefix=${INSTALL_PREFIX} --root=${INSTALL_DIR} --no-warn-script-location gvm-tools
sudo cp -rv ${INSTALL_DIR}/* /
#rm -rf ${INSTALL_DIR}/*

# Install redis-server
sudo apt-get install -y --no-install-recommends redis-server/buster-backports
sudo mkdir -p /etc/redis
sudo cp ${SOURCE_DIR}/openvas-scanner-${openvas_scanner_version}/config/redis-openvas.conf /etc/redis/redis-openvas.conf
sudo chown redis:redis /etc/redis/*.conf
echo "db_address = /run/redis-openvas/redis.sock" | sudo tee -a /etc/openvas/openvas.conf

sudo usermod -aG redis gvm

# Adjusting the permissions
sudo chown -R gvm:gvm /var/lib/gvm
sudo chown -R gvm:gvm /var/lib/openvas
sudo chown -R gvm:gvm /var/log/gvm
sudo chown -R gvm:gvm /run/gvm

sudo chmod -R g+srw /var/lib/gvm
sudo chmod -R g+srw /var/lib/openvas
sudo chmod -R g+srw /var/log/gvm

sudo chown gvm:gvm /usr/sbin/gvmd
sudo chmod 6750 /usr/sbin/gvmd

sudo chown gvm:gvm /usr/bin/greenbone-nvt-sync
sudo chmod 740 /usr/sbin/greenbone-feed-sync
sudo chown gvm:gvm /usr/sbin/greenbone-*-sync
sudo chmod 740 /usr/sbin/greenbone-*-sync

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
    nodejs \
    yarnpkg \
    graphviz-dev \
    cmake
sudo apt-get purge --auto-remove -y *-dev

sudo apt-get -y autoremove

echo "/usr/local/lib" >/etc/ld.so.conf.d/openvas.conf && ldconfig

rm -rf ${SOURCE_DIR} ${BUILD_DIR} ${INSTALL_DIR}
rm -rf /var/lib/apt/lists/*
rm /etc/apt/apt.conf.d/30proxy || true

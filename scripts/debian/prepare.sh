#!/usr/bin/env bash
set -Eexo pipefail

touch /opt/setup/.env

[ -z "$http_proxy" ] || echo "Acquire::http::Proxy \"${http_proxy}\";" | tee /etc/apt/apt.conf.d/30proxy
echo "APT::Install-Recommends \"0\" ; APT::Install-Suggests \"0\" ;" | tee /etc/apt/apt.conf.d/10no-recommend-installs

apt-get -qq update
apt-get install -yq --no-install-recommends gnupg curl wget sudo ca-certificates postfix supervisor cron openssh-server \
  nano lsb-release apt-utils xz-utils

export VERSION=node_14.x
export KEYRING=/etc/apt/keyrings/nodesource.gpg
export DISTRIBUTION="$(lsb_release -s -c)"

curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o $KEYRING
gpg --no-default-keyring --keyring "$KEYRING" --list-keys

NODE_MAJOR=20
echo "deb [signed-by=$KEYRING] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
printf 'Package: *\nPin: origin deb.nodesource.com\nPin-Priority: 600' > /etc/apt/preferences.d/nodesource

curl -fsS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
printf 'Package: *\nPin: origin dl.yarnpkg.com\nPin-Priority: 700' > /etc/apt/preferences.d/yarnpkg

sudo apt-get -qq update
sudo apt-get -yq upgrade

## START Postgres
sudo apt-get install -y postgresql postgresql-server-dev-all

sudo update-alternatives --install /usr/bin/postgres postgres /usr/lib/postgresql/1*/bin/postgres 30
sudo update-alternatives --install /usr/bin/initdb initdb /usr/lib/postgresql/1*/bin/initdb 40
#ln -s /usr/lib/postgresql/13/bin/postgres /usr/bin/postgres
#ln -s /usr/lib/postgresql/13/bin/initdb /usr/bin/initdb

sudo locale-gen en_US.UTF-8
sudo localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
## END Postgres

sudo apt-get install -y --no-install-recommends mosquitto yarn nodejs

sudo useradd -r -M -d /var/lib/gvm -U -G sudo -s /bin/bash gvm
sudo usermod -aG tty gvm
sudo usermod -aG sudo gvm

echo 'PATH="${HOME}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' | sudo tee /etc/profile.d/path.sh

#9 65.89 Generation complete.
#9 67.83 Usage: useradd [options] LOGIN
#9 67.83        useradd -D
#9 67.83        useradd -D [options]
#9 67.83
#9 67.83 Options:
#9 67.83   -b, --base-dir BASE_DIR       base directory for the home directory of the
#9 67.83                                 new account
#9 67.83   -c, --comment COMMENT         GECOS field of the new account
#9 67.83   -d, --home-dir HOME_DIR       home directory of the new account
#9 67.83   -D, --defaults                print or change default useradd configuration
#9 67.83   -e, --expiredate EXPIRE_DATE  expiration date of the new account
#9 67.83   -f, --inactive INACTIVE       password inactivity period of the new account
#9 67.83   -g, --gid GROUP               name or ID of the primary group of the new
#9 67.83                                 account
#9 67.83   -G, --groups GROUPS           list of supplementary groups of the new
#9 67.83                                 account
#9 67.83   -h, --help                    display this help message and exit
#9 67.83   -k, --skel SKEL_DIR           use this alternative skeleton directory
#9 67.83   -K, --key KEY=VALUE           override /etc/login.defs defaults
#9 67.83   -l, --no-log-init             do not add the user to the lastlog and
#9 67.83                                 faillog databases
#9 67.83   -m, --create-home             create the user's home directory
#9 67.83   -M, --no-create-home          do not create the user's home directory
#9 67.83   -N, --no-user-group           do not create a group with the same name as
#9 67.83                                 the user
#9 67.83   -o, --non-unique              allow to create users with duplicate
#9 67.83                                 (non-unique) UID
#9 67.83   -p, --password PASSWORD       encrypted password of the new account
#9 67.83   -r, --system                  create a system account
#9 67.83   -R, --root CHROOT_DIR         directory to chroot into
#9 67.83   -s, --shell SHELL             login shell of the new account
#9 67.83   -u, --uid UID                 user ID of the new account
#9 67.83   -U, --user-group              create a group with the same name as the user
#9 67.83   -Z, --selinux-user SEUSER     use a specific SEUSER for the SELinux user mapping
#9 67.83
#9 67.84 usermod: user 'gvm' does not exist
#9 67.85 usermod: user 'gvm' does not exist

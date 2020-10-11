#! /bin/bash

# system-packages_internal.sh
# Install support packages and configure system.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

dpkg --add-architecture i386
dpkg --configure -a

echo "Setting up locales"
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
apt install -y locales
echo "LC_ALL=en_US.UTF-8" >> /etc/environment
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8
dpkg-reconfigure --frontend noninteractive locales

echo "Checking if 32 bit and 64 bit architecture is supported1 ..."
apt update -y --no-install-recommends --no-install-suggests
apt upgrade -y --no-install-recommends --no-install-suggests

echo "Checking if 32 bit and 64 bit architecture is supported ..."

if [ "x$(dpkg --print-foreign-architectures)" != "xi386" ]; then
  echo "Failed to add 32 bit architecture."
  exit 2
fi

# Install all system dependencies.
apt-get install -y  --no-install-recommends --no-install-suggests sudo
apt-get install -y  --no-install-recommends --no-install-suggests libdbus-1-dev
apt-get install -y  --no-install-recommends --no-install-suggests dbus
apt-get install -y  --no-install-recommends --no-install-suggests dbus-user-session
apt-get install -y  --no-install-recommends --no-install-suggests ssh
apt-get install -y  --no-install-recommends --no-install-suggests wget
apt-get install -y  --no-install-recommends --no-install-suggests docker
apt-get install -y  --no-install-recommends --no-install-suggests docker.io
apt-get install -y  --no-install-recommends --no-install-suggests docker-compose

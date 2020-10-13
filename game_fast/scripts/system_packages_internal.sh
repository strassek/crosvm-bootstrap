#! /bin/bash

# system-packages_internal.sh
# Install support packages and configure system.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

echo "Installing needed system packages..."
function install_package() {
package_name="${1}"
if [ ! "$(dpkg -s $package_name)" ]; then
  echo "installing:" $package_name "----------------"
  apt-get install -y  --no-install-recommends --no-install-suggests $package_name
  apt-mark hold $package_name
  echo "---------------------"
else
  echo $package_name "is already installed."
fi
}

function install_package_i386() {
package_name="${1}"
if [ ! "$(dpkg -s $package_name:i386)" ]; then
  echo "installing:" $package_name:i386 "----------------"
  apt-mark unhold $package_name
  apt-get install -y  --no-install-recommends --no-install-suggests $package_name:i386
  apt-mark hold $package_name:i386
  echo "---------------------"
else
  echo $package_name:i386 "is already installed."
fi
}

apt update

install_package xfonts-cyrillic
install_package xfonts-100dpi
install_package xfonts-75dpi
install_package xfonts-base
install_package xauth
#install_package steam
install_package_i386 libc.so

apt autoremove -y

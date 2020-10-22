#! /bin/bash

# system-packages_internal.sh
# Install support packages and configure system.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

echo "Checking if 32 bit and 64 bit architecture is supported ..."

if [ "x$(dpkg --print-foreign-architectures)" != "xi386" ]; then
  echo "Failed to add 32 bit architecture."
  exit 2
fi


echo "Installing needed system packages..."
function install_package() {
package_name="${1}"
if [ ! "$(dpkg -s $package_name)" ]; then
  echo "installing:" $package_name "----------------"
  sudo apt-get install -y  --no-install-recommends --no-install-suggests $package_name
  sudo apt-mark hold $package_name
  echo "---------------------"
else
  echo $package_name "is already installed."
fi
}

function install_package_i386() {
package_name="${1}"
if [ ! "$(dpkg -s $package_name:i386)" ]; then
  echo "installing:" $package_name:i386 "----------------"
  sudo apt-mark unhold $package_name
  sudo apt-get install -y  --no-install-recommends --no-install-suggests $package_name:i386
  sudo apt-mark hold $package_name:i386
  echo "---------------------"
else
  echo $package_name:i386 "is already installed."
fi
}

sudo apt update
sudo ldconfig
sudo ldconfig -p

install_package libkmod-dev
install_package libprocps-dev
install_package libdw-dev
install_package gedit
install_package steam
install_package firefox
install_package libqt5waylandclient5
install_package libqt5waylandcompositor5
install_package qtwayland5
#install_package gnome-session-wayland
install_package qtcreator

sudo ldconfig
sudo ldconfig -p

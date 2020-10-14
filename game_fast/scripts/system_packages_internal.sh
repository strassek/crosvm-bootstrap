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

install_package libasound2
install_package libasound2-plugins
install_package libatk1.0
install_package libdbus-glib-1-2
install_package fontconfig
install_package freeglut3
install_package libfreetype6
install_package libgdk-pixbuf2.0-0
install_package libglew2.1
install_package libglib2.0-0
install_package libglu1-mesa
install_package libgtk-3-0
install_package gedit
install_package python-apt
install_package libgpg-error0
install_package libxcb-composite0-dev
install_package x11-xkb-utils
install_package libbsd-dev
install_package libxkbfile-dev
install_package libxfont-dev
install_package libxtst-dev
install_package_i386 libcurl4
install_package_i386 libstdc++6
install_package_i386 libgcc1
install_package_i386 zlib1g
install_package_i386 libncurses5
install_package_i386 libasound2
install_package_i386 libasound2-plugins
install_package_i386 libatk1.0
install_package_i386 libcairo2
install_package_i386 libcurl4
install_package_i386 libcurl4-gnutls-dev
install_package_i386 libdbusmenu-glib4
install_package_i386 libdbusmenu-gtk4
install_package_i386 libgcrypt20
install_package_i386 libice6
install_package_i386 dbus
install_package_i386 libdbus-glib-1-2
install_package_i386 fontconfig
install_package_i386 freeglut3
install_package_i386 libfreetype6
install_package_i386 libgdk-pixbuf2.0-0
install_package_i386 libglew2.1
install_package_i386 libglib2.0-0
install_package_i386 libglu1-mesa
install_package_i386 libgtk-3-0
install_package_i386 libappindicator3-1
install_package_i386 libcaca0
install_package_i386 libcanberra0
install_package_i386 libcups2

wget http://repo.steampowered.com/steam/archive/precise/steam_latest.deb
install_package gdebi-core
sudo gdebi -o APT::Install-Recommends=0 -o APT::Install-Suggests=0 --non-interactive steam_latest.deb
rm steam_latest.deb

sudo ldconfig
sudo ldconfig -p

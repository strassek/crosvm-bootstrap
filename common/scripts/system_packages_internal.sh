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
dpkg --add-architecture i386
dpkg --configure -a

apt-mark hold x11*
apt-mark hold xcb*
apt-mark hold *wayland*
apt-mark hold *gl*
apt-mark hold *drm*
apt-mark hold *gbm*

echo "Checking if 32 bit and 64 bit architecture is supported1 ..."
apt update -y --no-install-recommends --no-install-suggests
apt upgrade -y --no-install-recommends --no-install-suggests

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
    
install_package kmod
install_package libdbus-1-dev
install_package protobuf-compiler
install_package sudo
install_package ninja-build
install_package ssh
install_package git
install_package gcc
install_package g++
install_package xutils-dev
install_package autoconf
install_package nasm
install_package make
install_package python3-mako
install_package llvm
install_package libtool
install_package automake
install_package cmake
install_package pkg-config
install_package libatomic-ops-dev
install_package python3-setuptools
install_package python3-certifi
install_package gpgv2
install_package libffi-dev
install_package bison
install_package flex
install_package libcap-dev
install_package libfdt-dev
install_package curl
install_package dh-autoreconf
install_package libsensors4-dev
install_package libssl-dev
install_package libelf-dev
install_package bc
install_package libinput-dev
install_package libudev-dev
install_package libzstd-dev
install_package libunwind-dev
install_package python3-distutils
install_package libfontenc-dev
install_package wget
install_package gcc-i686-linux-gnu
install_package g++-i686-linux-gnu
install_package libgcrypt20
install_package libgcrypt20-dev
install_package libgpg-error-dev
install_package libfreetype6
install_package libfreetype6-dev
install_package libfontenc-dev
install_package libexpat1-dev
install_package xsltproc
install_package libxml2-utils
install_package libtool-bin
install_package libxml2-dev
install_package libc6-dev
install_package locales

echo "Installing needed i386 system packages..."
install_package_i386 libunwind-dev
install_package_i386 libsensors4-dev
install_package_i386  libelf-dev
install_package_i386 libselinux1
install_package_i386 libselinux1-dev
install_package_i386 libudev-dev
install_package_i386 libfreetype6
install_package_i386 libfreetype6-dev
install_package_i386 libfontenc-dev
install_package_i386 libffi-dev
install_package_i386 libexpat1-dev
install_package_i386 libc6-dev
install_package_i386 libxml2-dev
install_package_i386 zstd
install_package_i386 libzstd-dev

apt autoremove -y

echo "Installing Meson"
mkdir -p /intel
cd intel
git clone https://github.com/mesonbuild/meson
cd meson
git checkout origin/0.55
ln -s $PWD/meson.py /usr/bin/meson
    
# Export environment variables
export RUSTUP_HOME=/usr/local/rustup
export RUST_VERSION=1.45.2
export CARGO_HOME=/usr/local/cargo
export PATH=$CARGO_HOME:$PATH

cd ..

curl -LO "https://static.rust-lang.org/rustup/archive/1.22.1/x86_64-unknown-linux-gnu/rustup-init" \
    && echo "49c96f3f74be82f4752b8bffcf81961dea5e6e94ce1ccba94435f12e871c3bdb *rustup-init" | sha256sum -c -
chmod +x rustup-init
./rustup-init -y --no-modify-path --default-toolchain $RUST_VERSION
rm rustup-init
chmod -R a+w $RUSTUP_HOME $CARGO_HOME
source /usr/local/cargo/env
rustup --version
cargo --version
rustc --version
rustup default stable
cargo install thisiznotarealpackage -q || true

# Make sure we have libc packages correctly installed
if [ "$(dpkg -s linux-libc-dev:amd64 | grep ^Version:)" !=  "$(dpkg -s linux-libc-dev:i386 | grep ^Version:)" ]; then
  echo "linux-libc-dev:amd64 and linux-libc-dev:i386 do have different versions!"
  echo "Please fix this after rootfs is generated."
fi
if [ "$(dpkg -s libc6-dev:amd64 | grep ^Version:)" !=  "$(dpkg -s libc6-dev:i386 | grep ^Version:)" ]; then
  echo "libc6-dev:amd64 and libc6-dev:i386 do have different versions!"
  echo "Please fix this after rootfs is generated."
fi


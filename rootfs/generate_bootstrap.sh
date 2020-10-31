#! /bin/bash

# generate_bootstrap.sh
# Set up basic rootfs to be used by host, guest and containers.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

INCLUDE_PACKAGES=--include=libxkbfile1,libxkbfile-dev,kmod,g++,autoconf,make,python3-mako,pciutils,libtool,automake,cmake,pkg-config,libatomic-ops-dev,python3-setuptools,python3-certifi,libpixman-1-0,libpixman-1-dev,libffi-dev,bison,flex,libcap-dev,libfdt-dev,curl,dh-autoreconf,libsensors4-dev,libssl-dev,libelf-dev,bc,libinput-dev,libudev1,libzstd-dev,libunwind-dev,python3-distutils,libfontenc-dev,libgcrypt20,libgcrypt20-dev,libgpg-error-dev,libfreetype6,libfreetype6-dev,libfontenc-dev,libexpat1-dev,xsltproc,libxml2-utils,libtool-bin,libxml2-dev,libc6,libc6-dev,zlib1g,xauth,x11proto-dev,libxau6,libxcb-dri2-0,libxcb-dri2-0-dev,libxcb-dri3-0,libxcb-dri3-dev,xz-utils,fontconfig,fonts-liberation,libxcb-glx0,libxcb-glx0-dev,libxcb-present0,libxcb-present-dev,libxcb-randr0,libxcb-render0,libxcb-record0,libxcb-res0,libxcb-composite0,libxcb-damage0,libxcb-dpms0,libxcb-shape0,libxcb-shm0,libxcb-shm0-dev,libxcb-sync1,libxcb-xf86dri0,libxcb-xfixes0,libxcb-xinerama0,libxinerama-dev,libxcb-xinput0,libxcb-xkb1,libxcb-xkb-dev,libxcb-xv0,libxcb1,libx11-6,libx11-xcb1,libx11-xcb-dev,libx11-dev,libxext6,libxfixes3,libxdamage1,libxdamage-dev,libxshmfence1,libxshmfence-dev,libxxf86vm1,libxxf86vm-dev,libxrender1,libxrandr-dev,libxdmcp6,xkb-data,libxtst6,libxi6,libxss1,libexpat1-dev,libcairo2,libcairo2-dev,libxcb-composite0-dev,libxtst-dev,libxfont-dev,libpixman-1-0,libpixman-1-dev,xfonts-utils,xfonts-base

mkdir temp
cd temp
../debootstrap-ubuntu --arch=amd64 --make-tarball=rootfs_container.tar $INCLUDE_PACKAGES focal . http://archive.ubuntu.com/ubuntu/ || true
echo "created host bootstrap"
rm -rf ../rootfs_container.tar || true
mv rootfs_container.tar ../
rm -rf ../debootstrap-ubuntu
mv debootstrap/debootstrap ../debootstrap-ubuntu
cd ..
rm -rf temp

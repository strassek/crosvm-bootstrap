#! /bin/bash

# generate_bootstrap.sh
# Set up basic rootfs to be used by host, guest and containers.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

DEBIAN_VERSION=${1:-"buster"}

mkdir temp
cd temp
../debootstrap --arch=amd64 --make-tarball=rootfs_base.tar --variant=minbase $DEBIAN_VERSION . || true
echo "created bootstrap"
rm -rf ../rootfs_base.tar || true
mv rootfs_base.tar ../
rm -rf ../debootstrap
mv debootstrap/debootstrap ../
cd ..
rm -rf temp

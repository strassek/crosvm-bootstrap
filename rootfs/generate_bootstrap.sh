#! /bin/bash

# generate_bootstrap.sh
# Set up basic rootfs to be used by host, guest and containers.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

mkdir temp
cd temp
../debootstrap --arch=amd64 --make-tarball=rootfs_container.tar focal . http://archive.ubuntu.com/ubuntu/ || true
echo "created host bootstrap"
rm -rf ../rootfs_container.tar || true
mv rootfs_container.tar ../
rm -rf ../debootstrap
mv debootstrap/debootstrap ../debootstrap
cd ..
rm -rf temp

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
../debootstrap-debian --arch=amd64 --make-tarball=rootfs_base.tar buster . || true
echo "created Guest bootstrap"
rm -rf ../rootfs_base.tar || true
mv rootfs_base.tar ../
rm -rf ../debootstrap-debian
mv debootstrap/debootstrap ../debootstrap-debian
cd ..
rm -rf temp

mkdir temp
cd temp
../debootstrap-ubuntu --arch=amd64 --make-tarball=rootfs_container.tar focal . http://archive.ubuntu.com/ubuntu/ || true
echo "created host bootstrap"
rm -rf ../rootfs_container.tar || true
mv rootfs_container.tar ../
rm -rf ../debootstrap-ubuntu
mv debootstrap/debootstrap ../debootstrap-ubuntu
cd ..
rm -rf temp

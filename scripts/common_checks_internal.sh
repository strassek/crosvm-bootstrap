#! /bin/bash

# build-rootfs-builder-container.sh
# Set up build environment for docker container that generates Debian rootfs
# then calls docker build.

BUILD_ENVIRONMENT=$1

if [ $BUILD_ENVIRONMENT != "--chroot" ] && [ $BUILD_ENVIRONMENT != "--docker" ]; then
  echo "Invalid Build Environment. Valid Values:--chroot, --docker"
  exit 1
fi

if [ ! -e $PWD/build/ ]; then
  echo "Unable to re-build as Build folder is not found. Please run build.sh with --rebuild-rootfs to generate rootfs image first."
  exit 1
fi

if [ ! -e $PWD/build/output ]; then
  echo "Unable to re-build as Build folder is not found. Please run build.sh with --rebuild-rootfs to generate rootfs image first."
  exit 1
fi

if [ ! -e $PWD/build/output/rootfs.ext4 ]; then
  if [ $BUILD_ENVIRONMENT == "--docker" ]; then
    mkdir -p $PWD/build
  else
    echo "Unable to find rootfs.ext4 is not found. Please run build.sh with --rebuild-rootfs  to generate rootfs image first."
    exit 1
  fi
fi

if [ ! -e $PWD/source/source.ext4 ]; then
  if [ $BUILD_ENVIRONMENT == "--docker" ]; then
    mkdir -p $PWD/source
  else
    echo "Unable to find source.ext4. Please run build.sh with --rebuild-rootfs  to generate rootfs image first."
    exit 1
  fi
fi

echo "Copying latest build scripts"
rm -rf $PWD/build/output/scripts
mkdir -p $PWD/build/output/scripts

cp -rf scripts/*.* build/output/scripts/

rm -rf build/config
mkdir -p build/config
cp default-config/*.json build/config
cp -rf default-config/guest/ build/config/guest

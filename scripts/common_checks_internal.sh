#! /bin/bash

# build-rootfs-builder-container.sh
# Set up build environment for docker container that generates Debian rootfs
# then calls docker build.

LOCAL_PWD=${1}
LOCAL_SOURCE_PWD=${2}
BUILD_CHECK=${3:-"--false"}

echo "Recieved Arguments...."
echo "LOCAL_PWD:" $LOCAL_PWD
echo "LOCAL_SOURCE_PWD:" $LOCAL_SOURCE_PWD
echo "BUILD_CHECK:" $BUILD_CHECK
echo "--------------------------"

if [ ! -e $LOCAL_PWD/ ]; then
  echo "Unable to re-build as Build folder is not found. Please run build.sh with --rebuild-rootfs to generate rootfs image first."
  exit 1
fi

if [ ! -e $LOCAL_PWD/output ]; then
  echo "Unable to re-build as Build folder is not found. Please run build.sh with --rebuild-rootfs to generate rootfs image first."
  exit 1
fi

if [ ! -e $LOCAL_PWD/output/rootfs.ext4 ]; then
  if [ $BUILD_CHECK == "--true" ]; then
    mkdir -p $PWD/build
  else
    echo "Unable to find rootfs.ext4 is not found. Please run build.sh with --rebuild-rootfs  to generate rootfs image first."
    exit 1
  fi
fi

if [ ! -e $LOCAL_SOURCE_PWD/source/source.ext4 ]; then
  if [ $BUILD_CHECK == "--true" ]; then
    mkdir -p $PWD/source
  else
    echo "Unable to find source.ext4. Please run build.sh with --rebuild-rootfs  to generate rootfs image first."
    exit 1
  fi
fi

echo "Copying latest build scripts"
rm -rf $LOCAL_PWD/output/scripts
mkdir -p $LOCAL_PWD/output/scripts

cp -rf scripts/*.* $LOCAL_PWD/output/scripts/

rm -rf build/config
mkdir -p build/config
cp default-config/*.json $LOCAL_PWD/config
cp -rf default-config/guest/ $LOCAL_PWD/config/guest

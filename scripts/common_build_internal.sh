#! /bin/bash

# build-rootfs-builder-container.sh
# Set up build environment for docker container that generates Debian rootfs
# then calls docker build.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

BUILD_TYPE=${1}
CLEAN_BUILD=${2}
BUILD_CHANNEL=${3}
BUILD_ARCH=${4}

if [ $BUILD_ARCH != "--64bit" ] && [ $BUILD_ARCH != "--32bit" ]; then
  echo "Invalid Build Arch. Valid Values:--64bit, --32bit"
  exit
fi

if [ $CLEAN_BUILD != "--clean" ] && [ $CLEAN_BUILD != "--incremental" ]; then
  echo "Invalid Build Type. Valid Values:--clean, --incremental"
  exit
fi

if [ $BUILD_CHANNEL != "--dev" ] && [ $BUILD_CHANNEL != "--stable" ]; then
 echo "Invalid Build Channel. Valid Values: --dev, --stable, --all"
 exit
fi

if [ $BUILD_TYPE != "--release" ] && [ $BUILD_TYPE != "--debug" ] ]; then
 echo "Invalid Build Channel. Valid Values: --release, --debug, --all"
 exit
fi

echo "Passed parameters:----------------"
echo "BUILD_TYPE" $BUILD_TYPE
echo "CLEAN_BUILD" $CLEAN_BUILD
echo "BUILD_CHANNEL" $BUILD_CHANNEL
echo "BUILD_ARCH" $BUILD_ARCH
echo "------------------------------"

if [ $BUILD_ARCH == "--64bit" ]; then
  # print gcc environment
  echo "C environment settings---------"
  gcc -xc -E -v
  echo "---------------------------------"
  echo "C++ environment settings------------"
  gcc -xc++ -E -v
  echo "---------------------------------"

  env
  echo "---------------------------------"
else
  export CC=/usr/bin/i686-linux-gnu-gcc

  # print gcc environment
  echo "C environment settings------------"
  i686-linux-gnu-gcc -xc -E -v
  echo "---------------------------------"
  echo "C++ environment settings----------"
  i686-linux-gnu-gcc -xc++ -E -v
  echo "---------------------------------"
fi

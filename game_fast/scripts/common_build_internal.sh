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
BUILD_TARGET=${2}
BUILD_CHANNEL=${3}

if [ $BUILD_TYPE != "--clean" ] && [ $BUILD_TYPE != "--incremental" ]; then
  echo "Invalid Build Type. Valid Values:--clean, --incremental Recieved:" $BUILD_TYPE
  exit 1
fi

if [ $BUILD_CHANNEL != "--dev" ] && [ $BUILD_CHANNEL != "--stable" ]; then
 echo "Invalid Build Channel. Valid Values: --dev, --stable, --all Recieved:" $BUILD_CHANNEL
 exit 1
fi

if [ $BUILD_TARGET != "--release" ] && [ $BUILD_TARGET != "--debug" ] ]; then
 echo "Invalid Build Channel. Valid Values: --release, --debug, --all. Recieved:" $BUILD_TYPE
 exit 1
fi

echo "Passed parameters:----------------"
echo "BUILD_TYPE" $BUILD_TYPE
echo "BUILD_TARGET" $BUILD_TARGET
echo "BUILD_CHANNEL" $BUILD_CHANNEL
echo "------------------------------"

# print gcc environment
echo "C environment settings---------"
gcc -xc -E -v
echo "---------------------------------"
echo "C++ environment settings------------"
gcc -xc++ -E -v
echo "---------------------------------"

env
echo "---------------------------------"

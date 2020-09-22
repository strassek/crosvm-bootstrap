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

MOUNT_SYSTEM_DIRS=${1:-"--false"}
MOUNT_SOURCE_IMAGE=${2:-"--true"}
MOUNT_OUTPUT_DIR=${3:-"--true"}
BUILD_ENVIRONMENT=${4:-"--chroot"}
MOUNT_POINT=${5:-"mount"}

echo "Recieved Arguments...."
echo "MOUNT_SYSTEM_DIRS:" $MOUNT_SYSTEM_DIRS
echo "MOUNT_SOURCE_IMAGE:" $MOUNT_SOURCE_IMAGE
echo "MOUNT_OUTPUT_DIR:" $MOUNT_OUTPUT_DIR
echo "BUILD_ENVIRONMENT:" $BUILD_ENVIRONMENT
echo "MOUNT_POINT:" $MOUNT_POINT
echo "--------------------------"

LOCAL_DIRECTORY_PREFIX=$PWD
LOCAL_SOURCE=$PWD/source

if [ $BUILD_ENVIRONMENT == "--docker" ]; then
LOCAL_DIRECTORY_PREFIX=/app
LOCAL_SOURCE=/app
fi

echo "Parameters used for Mount...."
echo "MOUNT_SYSTEM_DIRS:" $MOUNT_SYSTEM_DIRS
echo "MOUNT_SOURCE_IMAGE:" $MOUNT_SOURCE_IMAGE
echo "MOUNT_OUTPUT_DIR:" $MOUNT_OUTPUT_DIR
echo "BUILD_ENVIRONMENT:" $BUILD_ENVIRONMENT
echo "MOUNT_POINT:" $MOUNT_POINT
echo "LOCAL_DIRECTORY_PREFIX:" $LOCAL_DIRECTORY_PREFIX
echo "--------------------------"

# Create all needed directories.
mkdir -p $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT

mount $LOCAL_DIRECTORY_PREFIX/output/rootfs.ext4 $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT


if [ $MOUNT_SOURCE_IMAGE == "--true" ]; then
  mkdir -p $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/build
  mount $LOCAL_SOURCE/source/source.ext4 $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/build
fi

if [ $MOUNT_SYSTEM_DIRS == "--true" ]; then
  echo "Configuring chroot environment"
  mkdir -p $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/proc
  mkdir -p $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/dev/shm
  mkdir -p $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/dev/pts
  mount -t proc /proc $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/proc
  mount -o bind /dev/shm $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/dev/shm
  mount -o bind /dev/pts $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/dev/pts
fi

if [ $MOUNT_OUTPUT_DIR == "--true" ]; then
  mkdir -p $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/build/output
  mount -o bind $LOCAL_DIRECTORY_PREFIX/output $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/build/output

  mkdir -p $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/build/output/stable
  mkdir -p $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/build/output/dev

  mkdir -p $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/build/output/stable/debug
  mkdir -p $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/build/output/stable/release

  mkdir -p $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/build/output/dev/debug
  mkdir -p $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/build/output/dev/release
fi

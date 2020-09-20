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

UNMOUNT_SYSTEM_DIRS=${1:-"--false"}
UNMOUNT_SOURCE_IMAGE=${2:-"--true"}
UNMOUNT_OUTPUT_DIR=${3:-"--true"}
BUILD_ENVIRONMENT=${4:-"--chroot"}
UNMOUNT_POINT=${5:-"mount"}

echo "Recieved Arguments for UnMount...."
echo "UNMOUNT_SYSTEM_DIRS:" $UNMOUNT_SYSTEM_DIRS
echo "UNMOUNT_SOURCE_IMAGE: $UNMOUNT_SOURCE_IMAGE"
echo "UNMOUNT_OUTPUT_DIR: $UNMOUNT_OUTPUT_DIR"
echo "BUILD_ENVIRONMENT:" $BUILD_ENVIRONMENT
echo "UNMOUNT_POINT:" $UNMOUNT_POINT
echo "--------------------------"

LOCAL_DIRECTORY_PREFIX=$PWD/build

if [ $BUILD_ENVIRONMENT == "--docker" ]; then
LOCAL_DIRECTORY_PREFIX=/app
fi

echo "Parameters used...."
echo "UNMOUNT_SYSTEM_DIRS:" $UNMOUNT_SYSTEM_DIRS
echo "UNMOUNT_SOURCE_IMAGE: $UNMOUNT_SOURCE_IMAGE"
echo "UNMOUNT_OUTPUT_DIR: $UNMOUNT_OUTPUT_DIR"
echo "BUILD_ENVIRONMENT:" $BUILD_ENVIRONMENT
echo "UNMOUNT_POINT:" $UNMOUNT_POINT
echo "LOCAL_DIRECTORY_PREFIX:" $LOCAL_DIRECTORY_PREFIX
echo "--------------------------"

if [ $UNMOUNT_OUTPUT_DIR == "--true" ]; then
  umount $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/build/output
fi

if [ $UNMOUNT_SYSTEM_DIRS == "--true" ]; then
  umount $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/proc
  umount $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/dev/shm
  umount $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/dev/pts
fi

if [ $UNMOUNT_SOURCE_IMAGE == "--true" ]; then
  umount $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/build
fi

umount $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT

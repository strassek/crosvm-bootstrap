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
LOCAL_PWD=${4}
UNMOUNT_POINT=${5:-"mount"}

echo "Recieved Arguments for UnMount...."
echo "UNMOUNT_SYSTEM_DIRS:" $UNMOUNT_SYSTEM_DIRS
echo "UNMOUNT_SOURCE_IMAGE: $UNMOUNT_SOURCE_IMAGE"
echo "UNMOUNT_OUTPUT_DIR: $UNMOUNT_OUTPUT_DIR"
echo "LOCAL_PWD:" $LOCAL_PWD
echo "UNMOUNT_POINT:" $UNMOUNT_POINT
echo "--------------------------"

LOCAL_DIRECTORY_PREFIX=$LOCAL_PWD

echo "Parameters used...."
echo "UNMOUNT_SYSTEM_DIRS:" $UNMOUNT_SYSTEM_DIRS
echo "UNMOUNT_SOURCE_IMAGE: $UNMOUNT_SOURCE_IMAGE"
echo "UNMOUNT_OUTPUT_DIR: $UNMOUNT_OUTPUT_DIR"
echo "UNMOUNT_POINT:" $UNMOUNT_POINT
echo "LOCAL_DIRECTORY_PREFIX:" $LOCAL_DIRECTORY_PREFIX
echo "--------------------------"

if [ $UNMOUNT_OUTPUT_DIR == "--true" ]; then
  if mount | grep $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/build/output > /dev/null; then
    echo "unmounting" $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/build/output
    umount $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/build/output
  fi
fi

if [ $UNMOUNT_SYSTEM_DIRS == "--true" ]; then
  if mount | grep $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/proc > /dev/null; then
    echo "unmounting" $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/proc
    umount $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/proc
  fi
  
  if mount | grep $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/dev/shm > /dev/null; then
    echo "unmounting" $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/dev/shm
    umount $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/dev/shm
  fi
  
    if mount | grep $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/dev/pts > /dev/null; then
    echo "unmounting" $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/dev/pts
    umount $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/dev/pts
  fi
fi

if [ $UNMOUNT_SOURCE_IMAGE == "--true" ]; then
  if mount | grep $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/build > /dev/null; then
    echo "unmounting" $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/build
    umount $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/build
  fi
fi

if mount | grep $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT > /dev/null; then
  echo "unmounting" $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT
  umount $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT
fi

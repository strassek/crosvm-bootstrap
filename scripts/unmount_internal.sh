#! /bin/bash

# build-rootfs-builder-container.sh
# Set up build environment for docker container that generates Debian rootfs
# then calls docker build.

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

UNMOUNT_SYSTEM_DIRS=${1:-"--false"}
UNMOUNT_SOURCE_IMAGE=${2:-"--true"}
UNMOUNT_OUTPUT_DIR=${3:-"--true"}
DIRECTORY_PREFIX=${4}
UNMOUNT_POINT=${5}

echo "unmount_internal: Recieved Arguments for UnMount...."
echo "UNMOUNT_SYSTEM_DIRS:" $UNMOUNT_SYSTEM_DIRS
echo "UNMOUNT_SOURCE_IMAGE: $UNMOUNT_SOURCE_IMAGE"
echo "UNMOUNT_OUTPUT_DIR: $UNMOUNT_OUTPUT_DIR"
echo "DIRECTORY_PREFIX:" $DIRECTORY_PREFIX
echo "UNMOUNT_POINT:" $UNMOUNT_POINT
echo "--------------------------"

LOCAL_DIRECTORY_PREFIX=$DIRECTORY_PREFIX

echo "unmount_internal: Parameters used...."
echo "UNMOUNT_SYSTEM_DIRS:" $UNMOUNT_SYSTEM_DIRS
echo "UNMOUNT_SOURCE_IMAGE: $UNMOUNT_SOURCE_IMAGE"
echo "UNMOUNT_OUTPUT_DIR: $UNMOUNT_OUTPUT_DIR"
echo "UNMOUNT_POINT:" $UNMOUNT_POINT
echo "LOCAL_DIRECTORY_PREFIX:" $LOCAL_DIRECTORY_PREFIX
echo "--------------------------"

if [ $UNMOUNT_OUTPUT_DIR == "--true" ]; then
  if mount | grep $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/build/output > /dev/null; then
    echo "unmounting" $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/build/output
    umount -l $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/build/output
  fi
fi

if [ $UNMOUNT_SYSTEM_DIRS == "--true" ]; then
  if mount | grep $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/proc > /dev/null; then
    echo "unmounting" $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/proc
    umount -l $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/proc
  fi
  
  if mount | grep $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/dev/shm > /dev/null; then
    echo "unmounting" $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/dev/shm
    umount -l $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/dev/shm
  fi
  
    if mount | grep $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/dev/pts > /dev/null; then
    echo "unmounting" $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/dev/pts
    umount -l $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/dev/pts
  fi
fi

if [ $UNMOUNT_SOURCE_IMAGE == "--true" ]; then
  if mount | grep $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/build > /dev/null; then
    echo "unmounting" $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/build
    umount -l $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/build
  fi
fi

if [ -e $LOCAL_DIRECTORY_PREFIX/output/host.ext4 ]; then
  if mount | grep $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/host > /dev/null; then
    echo "unmounting" $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/host
    umount -l $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT/host
  fi
fi

if mount | grep $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT > /dev/null; then
  echo "unmounting" $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT
  umount -l $LOCAL_DIRECTORY_PREFIX/$UNMOUNT_POINT
fi

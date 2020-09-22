#! /bin/bash

# build-rootfs-builder-container.sh
# Set up build environment for docker container that generates Debian rootfs
# then calls docker build.

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

MOUNT_SYSTEM_DIRS=${1:-"--false"}
MOUNT_SOURCE_IMAGE=${2:-"--true"}
MOUNT_OUTPUT_DIR=${3:-"--true"}
DIRECTORY_PREFIX=${4}
DIRECTORY_SOURCE_PREFIX=${5}
MOUNT_POINT=${6}

echo "Recieved Arguments...."
echo "MOUNT_SYSTEM_DIRS:" $MOUNT_SYSTEM_DIRS
echo "MOUNT_SOURCE_IMAGE:" $MOUNT_SOURCE_IMAGE
echo "MOUNT_OUTPUT_DIR:" $MOUNT_OUTPUT_DIR
echo "DIRECTORY_PREFIX:" $DIRECTORY_PREFIX
echo "DIRECTORY_SOURCE_PREFIX:" $DIRECTORY_SOURCE_PREFIX
echo "MOUNT_POINT:" $MOUNT_POINT
echo "--------------------------"

LOCAL_DIRECTORY_PREFIX=$DIRECTORY_PREFIX
LOCAL_SOURCE=$DIRECTORY_SOURCE_PREFIX

echo "Parameters used for Mount...."
echo "MOUNT_SYSTEM_DIRS:" $MOUNT_SYSTEM_DIRS
echo "MOUNT_SOURCE_IMAGE:" $MOUNT_SOURCE_IMAGE
echo "MOUNT_OUTPUT_DIR:" $MOUNT_OUTPUT_DIR
echo "LOCAL_DIRECTORY_PREFIX:" $LOCAL_DIRECTORY_PREFIX
echo "LOCAL_SOURCE:" $LOCAL_SOURCE
echo "MOUNT_POINT:" $MOUNT_POINT
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

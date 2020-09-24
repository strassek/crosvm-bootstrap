#! /bin/bash

# build-rootfs-builder-container.sh
# Set up build environment for docker container that generates Debian rootfs
# then calls docker build.

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

IMAGE_PATH=${1}
MOUNT_POINT=${2}

echo "Recieved Arguments...."
echo "MOUNT_POINT:" $MOUNT_POINT
echo "IMAGE_PATH:" $IMAGE_PATH
echo "--------------------------"


# Create all needed directories.
mkdir -p $MOUNT_POINT

if mount | grep $MOUNT_POINT > /dev/null; then
  echo "unmounting" $MOUNT_POINT
  umount -l $MOUNT_POINT
fi

mount $IMAGE_PATH $MOUNT_POINT

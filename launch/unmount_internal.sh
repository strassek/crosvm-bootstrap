#! /bin/bash

# build-rootfs-builder-container.sh
# Set up build environment for docker container that generates Debian rootfs
# then calls docker build.

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

UNMOUNT_POINT=${1}

if mount | grep $UNMOUNT_POINT > /dev/null; then
  echo "unmounting" $UNMOUNT_POINT
  umount -l $UNMOUNT_POINT
fi

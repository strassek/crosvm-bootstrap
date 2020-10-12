#! /bin/bash

# build-guest-internal.sh
# Builds xserver and sommelier packages needed on GUEST side.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

BASE_PWD=${1}
BUILD_TYPE=${2:-"--none"}
UPDATE_CONTAINERS=${3:-"--true"}

LOCAL_PWD=$BASE_PWD/build
SOURCE_PWD=$BASE_PWD/source
LOG_DIR=$LOCAL_PWD/log/guest
SCRIPTS_DIR=$LOCAL_PWD/scripts/guest

# Rootfs Names
LOCAL_ROOTFS_GUEST=rootfs_guest
LOCAL_ROOTFS_GUEST_MOUNT_DIR=rootfs_guest-temp
LOCAL_ROOTFS_BASE=rootfs_base
LOCAL_ROOTFS_GAME_FAST_CONTAINER=rootfs_game_fast

mkdir -p $LOG_DIR

source $SCRIPTS_DIR/error_handler_internal.sh $LOG_DIR guest.log $LOCAL_PWD

update_containers() {
if [ $UPDATE_CONTAINERS == "--true" ]; then
  echo "Updating Containers---"
  mkdir -p $LOCAL_ROOTFS_GUEST_MOUNT_DIR
  sudo mount $LOCAL_ROOTFS_GUEST.ext4 $LOCAL_ROOTFS_GUEST_MOUNT_DIR/
  sudo rm -rf $LOCAL_ROOTFS_GUEST_MOUNT_DIR/intel/containers
  sudo mkdir $LOCAL_ROOTFS_GUEST_MOUNT_DIR/intel/containers

  if [ -e $LOCAL_ROOTFS_GUEST_MOUNT_DIR/scripts/guest ]; then
    sudo rm -rf $LOCAL_ROOTFS_GUEST_MOUNT_DIR/scripts/guest
  fi

  sudo mkdir -p $LOCAL_ROOTFS_GUEST_MOUNT_DIR/scripts/guest
  sudo cp -rf $LOCAL_PWD/scripts/guest/*.* $LOCAL_ROOTFS_GUEST_MOUNT_DIR/scripts/guest/

  sudo cp $LOCAL_PWD/containers/rootfs_game_fast.ext4 $LOCAL_ROOTFS_GUEST_MOUNT_DIR/intel/containers/

  sudo chroot $LOCAL_ROOTFS_GUEST_MOUNT_DIR/ /bin/bash /scripts/guest/container_settings.sh

  sudo rm -rf $LOCAL_ROOTFS_GUEST_MOUNT_DIR/scripts
  sudo umount -l $LOCAL_ROOTFS_GUEST_MOUNT_DIR
  rm -rf $LOCAL_ROOTFS_GUEST_MOUNT_DIR
fi
}

# Handle base builds
mkdir -p $LOCAL_PWD/images
cd $LOCAL_PWD/images

echo $UPDATE_CONTAINERS

# Generate Containers.
update_containers





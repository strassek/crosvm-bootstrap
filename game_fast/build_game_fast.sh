#! /bin/bash

# build-game_fast-internal.sh
# Builds xserver and sommelier packages needed on game_fast side.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

BASE_PWD=${1}
COMPONENT_TARGET=${2:-"--none"}
BUILD_TYPE=${3:-"--clean"} # Possible values: --clean, --incremental --really-clean
COMPONENT_ONLY_BUILDS=${4:-"--all"}
BUILD_CHANNEL=${5:-"--stable"} # Possible values: --dev, --stable, --all
BUILD_TARGET=${6:-"--release"} # Possible values: --release, --debug, --all
CREATE_BASE_IMAGE_ONLY=${7:-"--false"} # Possible values: --false, --true

LOCAL_PWD=$BASE_PWD/build
SOURCE_PWD=$BASE_PWD/source
LOCAL_BUILD_TYPE=$BUILD_TYPE
LOCAL_COMPONENT_ONLY_BUILDS=$COMPONENT_ONLY_BUILDS
LOG_DIR=$LOCAL_PWD/log/game_fast
SCRIPTS_DIR=$LOCAL_PWD/scripts/game_fast

# Rootfs Names
LOCAL_ROOTFS_GAME_FAST=rootfs_game_fast
LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR=rootfs_game_fast-temp
LOCAL_ROOTFS_COMMON=rootfs_common

mkdir -p $LOG_DIR

if bash game_fast/scripts/common_checks_internal.sh $COMPONENT_TARGET $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET; then
  echo “Preparing to build vm...”
else
  echo “Failed to find needed dependencies, exit status: $?”
  exit 1
fi

source $SCRIPTS_DIR/error_handler_internal.sh $LOG_DIR game_fast.log $LOCAL_PWD

generate_game_fast() {
if [ -e $LOCAL_ROOTFS_GAME_FAST.ext4 ]; then
  echo "Game Fast rootfs image already exists. Reusing it."
  return 0;
fi

if [ ! -e $LOCAL_PWD/containers/$LOCAL_ROOTFS_COMMON.ext4 ]; then
  echo "Common rootfs image doesn't exists. Please build it first."
  exit 1
fi

echo "Preparing rootfs image for game_fast..."
cp -rf $LOCAL_PWD/containers/$LOCAL_ROOTFS_COMMON.ext4 $LOCAL_ROOTFS_GAME_FAST.ext4
mkdir -p $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR
sudo mount $LOCAL_ROOTFS_GAME_FAST.ext4 $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR/

sudo mkdir -p $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR/scripts/game_fast/
sudo cp $LOCAL_PWD/scripts/game_fast/*.sh $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR/scripts/game_fast/

sudo cp -rvf $LOCAL_PWD/config/default-config/common/* $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR/
sudo cp -rvf $LOCAL_PWD/config/default-config/guest/* $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR/
sudo cp -rvf $LOCAL_PWD/config/default-config/container/* $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR/

echo "enabling needed services"
sudo chroot $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR/ /bin/bash /scripts/game_fast/services_internal.sh

echo "Rootfs image for game_fast is ready. Preparing to compile game_fast packages..."
sudo umount -l $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR
if [ ! -e $LOCAL_ROOTFS_GAME_FAST.lock ]; then
  echo "rootfs generated" > $LOCAL_ROOTFS_GAME_FAST.lock
fi
}

cleanup_build_env() {
if [ -e $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR ]; then
  if mount | grep $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR/build > /dev/null; then
    sudo umount -l $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR/build
  fi

  if mount | grep $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR/log/game_fast > /dev/null; then
    sudo umount -l $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR/log/game_fast
  fi

  if mount | grep $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR > /dev/null; then
    sudo umount -l $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR
  fi

  rm -rf $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR
fi
}

destroy_game_fast_rootfs_as_needed() {
cleanup_build_env

if [ $BUILD_TYPE == "--really-clean" ]; then
  if [ -e $LOCAL_ROOTFS_GAME_FAST.lock ]; then
    rm $LOCAL_ROOTFS_GAME_FAST.lock
  fi

  if [ -e $LOCAL_PWD/containers/$LOCAL_ROOTFS_GAME_FAST.ext4 ]; then
    rm  $LOCAL_PWD/containers/$LOCAL_ROOTFS_GAME_FAST.ext4
  fi

  LOCAL_BUILD_TYPE=--clean
fi
}

setup_build_env() {
if [ ! -e $LOCAL_ROOTFS_GAME_FAST.ext4 ]; then
  echo "Cannot find chroot..."
  exit 1
fi

mkdir -p $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR
sudo mount $LOCAL_ROOTFS_GAME_FAST.ext4 $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR/

if [ -e $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR/scripts/game_fast ]; then
  sudo rm -rf $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR/scripts/game_fast
fi

if [ -e $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR/log/game_fast ]; then
  sudo rm -rf $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR/log/game_fast
fi

sudo mkdir -p $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR/build
sudo mkdir -p $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR/scripts/game_fast
sudo mkdir -p $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR/log/game_fast
sudo mount --rbind $SOURCE_PWD $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR/build
sudo mount --rbind $BASE_PWD/build/log/game_fast $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR/log/game_fast
sudo cp $LOCAL_PWD/scripts/game_fast/*.sh $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR/scripts/game_fast/
}

# Handle base builds
mkdir -p $LOCAL_PWD/containers
cd $LOCAL_PWD/containers
destroy_game_fast_rootfs_as_needed

# Generate rootfs if needed
generate_game_fast

setup_build_env

echo "Building packages..."
if sudo chroot $LOCAL_ROOTFS_GAME_FAST_MOUNT_DIR/ /bin/bash /scripts/game_fast/main.sh $LOCAL_BUILD_TYPE --all $BUILD_CHANNEL $BUILD_TARGET; then
  echo "Game Fast Container Ready."
else
  exit 1
fi

cleanup_build_env

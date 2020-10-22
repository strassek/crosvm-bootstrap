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

BASE_PWD=${1}
COMPONENT_TARGET=${2:-"--none"}
BUILD_TYPE=${3:-"--clean"} # Possible values: --clean, --incremental --really-clean
COMPONENT_ONLY_BUILDS=${4:-"--all"}
BUILD_CHANNEL=${5:-"--stable"} # Possible values: --dev, --stable, --all
BUILD_TARGET=${6:-"--release"} # Possible values: --release, --debug, --all

LOCAL_PWD=$BASE_PWD/build
SOURCE_PWD=$BASE_PWD/source
LOCAL_BUILD_TYPE=$BUILD_TYPE
LOCAL_COMPONENT_ONLY_BUILDS=$COMPONENT_ONLY_BUILDS
LOG_DIR=$LOCAL_PWD/log/host
SCRIPTS_DIR=$LOCAL_PWD/scripts/host

# Rootfs Names
LOCAL_ROOTFS_HOST=rootfs_host
LOCAL_ROOTFS_HOST_MOUNT_DIR=rootfs_host-temp
LOCAL_ROOTFS_COMMON=rootfs_common

mkdir -p $LOG_DIR

if bash host/scripts/common_checks_internal.sh $COMPONENT_TARGET $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET; then
  echo “Preparing to build vm...”
else
  echo “Failed to find needed dependencies, exit status: $?”
  exit 1
fi

source $SCRIPTS_DIR/error_handler_internal.sh $LOG_DIR host.log $LOCAL_PWD

cleanup_build_env() {
if [ -e $LOCAL_ROOTFS_HOST_MOUNT_DIR ]; then
  if mount | grep $LOCAL_ROOTFS_HOST_MOUNT_DIR/build > /dev/null; then
    sudo umount -l $LOCAL_ROOTFS_HOST_MOUNT_DIR/build
  fi

  if mount | grep $LOCAL_ROOTFS_HOST_MOUNT_DIR/log/host > /dev/null; then
    sudo umount -l $LOCAL_ROOTFS_HOST_MOUNT_DIR/log/host
  fi

  if mount | grep $LOCAL_ROOTFS_HOST_MOUNT_DIR > /dev/null; then
    sudo umount -l $LOCAL_ROOTFS_HOST_MOUNT_DIR
  fi

  if mount | grep $LOCAL_ROOTFS_HOST_MOUNT_DIR/proc > /dev/null; then
    sudo umount -l $LOCAL_ROOTFS_MOUNT_DIR/proc
  fi

  if mount | grep $LOCAL_ROOTFS_HOST_MOUNT_DIR/dev/shm > /dev/null; then
    sudo umount -l $LOCAL_ROOTFS_MOUNT_DIR/dev/shm
  fi

  if mount | grep $LOCAL_ROOTFS_HOST_MOUNT_DIR/dev/pt > /dev/null; then
    sudo umount -l $LOCAL_ROOTFS_MOUNT_DIR/dev/pt
  fi

  rm -rf $LOCAL_ROOTFS_HOST_MOUNT_DIR
fi
}

setup_build_env() {
if [ ! -e $LOCAL_ROOTFS_HOST.ext4 ]; then
  echo "Cannot find chroot..."
  exit 1
fi

mkdir -p $LOCAL_ROOTFS_HOST_MOUNT_DIR
sudo mount $LOCAL_ROOTFS_HOST.ext4 $LOCAL_ROOTFS_HOST_MOUNT_DIR/

if [ ! -e $LOCAL_ROOTFS_HOST_MOUNT_DIR/scripts/host ]; then
  sudo rm -rf $LOCAL_ROOTFS_HOST_MOUNT_DIR/scripts/host
fi

if [ ! -e $LOCAL_ROOTFS_HOST_MOUNT_DIR/log/host ]; then
  sudo rm -rf $LOCAL_ROOTFS_HOST_MOUNT_DIR/log/host
fi

sudo mkdir -p $LOCAL_ROOTFS_HOST_MOUNT_DIR/build
sudo mkdir -p $LOCAL_ROOTFS_HOST_MOUNT_DIR/scripts/host
sudo mkdir -p $LOCAL_ROOTFS_HOST_MOUNT_DIR/log/host

sudo mkdir -p $LOCAL_ROOTFS_HOST_MOUNT_DIR/proc
sudo mkdir -p $LOCAL_ROOTFS_HOST_MOUNT_DIR/dev/shm
sudo mkdir -p $LOCAL_ROOTFS_HOST_MOUNT_DIR/dev/pts
sudo mount -t proc /proc $LOCAL_ROOTFS_HOST_MOUNT_DIR/proc
sudo mount -o bind /dev/shm $LOCAL_ROOTFS_HOST_MOUNT_DIR/dev/shm
sudo mount -o bind /dev/pts $LOCAL_ROOTFS_HOST_MOUNT_DIR/dev/pts

sudo mount --rbind $SOURCE_PWD $LOCAL_ROOTFS_HOST_MOUNT_DIR/build
sudo mount --rbind $BASE_PWD/build/log/host $LOCAL_ROOTFS_HOST_MOUNT_DIR/log/host
sudo cp $LOCAL_PWD/scripts/host/*.sh $LOCAL_ROOTFS_HOST_MOUNT_DIR/scripts/host/
}

# Handle base builds
mkdir -p $LOCAL_PWD/containers
cd $LOCAL_PWD/containers

setup_build_env

echo "Building host."
if sudo chroot $LOCAL_ROOTFS_HOST_MOUNT_DIR/ /bin/bash /scripts/host/main.sh $LOCAL_BUILD_TYPE --all $BUILD_CHANNEL $BUILD_TARGET; then
  echo "Built------------"
else
  exit 1
fi

cleanup_build_env

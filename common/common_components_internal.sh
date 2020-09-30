#! /bin/bash

# common_components.sh
# Compiles all common packages needde by Guest and Host.
# Creates temporary image which is to be used for Guest
# and Host side.

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
LOG_DIR=$BASE_PWD/build/log/common
SCRIPTS_DIR=$LOCAL_PWD/scripts

# Rootfs Names
LOCAL_ROOTFS_BASE=rootfs_base
LOCAL_ROOTFS_COMMON=rootfs_common
LOCAL_ROOTFS_COMMON_MOUNT_DIR=rootfs_common-temp

mkdir -p $BASE_PWD/build/log/common

if bash common/scripts/common_checks_internal.sh $LOCAL_PWD $SOURCE_PWD --true --false $COMPONENT_TARGET $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET  $CREATE_BASE_IMAGE_ONLY; then
  echo “Preparing to build common components...”
else
  echo “Failed to find needed dependencies, exit status: $?”
  exit 1
fi

source $SCRIPTS_DIR/common/error_handler_internal.sh $LOG_DIR common_component_setup.log $LOCAL_PWD

generate_component_rootfs() {
if [ -e $LOCAL_ROOTFS_COMMON.ext4 ]; then
  echo "Component rootfs image already exists. Reusing it."
  return 0;
fi

if [ ! -e $LOCAL_ROOTFS_BASE.ext4 ]; then
  echo "Base rootfs image doesn't exists. Please build it first."
  exit 1
fi

echo "Preparing rootfs images for building common components..."
cp -rf $LOCAL_ROOTFS_BASE.ext4 $LOCAL_ROOTFS_COMMON.ext4
if [ ! -e $LOCAL_ROOTFS_COMMON.lock ]; then
  echo "rootfs generated" > $LOCAL_ROOTFS_COMMON.lock
fi
}

cleanup_build_env() {
if [ -e $LOCAL_ROOTFS_COMMON_MOUNT_DIR ]; then
  if sudo mount | grep $LOCAL_ROOTFS_COMMON_MOUNT_DIR/build > /dev/null; then
    sudo umount -l $LOCAL_ROOTFS_COMMON_MOUNT_DIR/build
  fi

  if sudo mount | grep $LOCAL_ROOTFS_COMMON_MOUNT_DIR/log/common > /dev/null; then
    sudo umount -l $LOCAL_ROOTFS_COMMON_MOUNT_DIR/log/common
  fi

  if sudo mount | grep $LOCAL_ROOTFS_COMMON_MOUNT_DIR > /dev/null; then
    sudo umount -l $LOCAL_ROOTFS_COMMON_MOUNT_DIR
  fi

  rm -rf $LOCAL_ROOTFS_COMMON_MOUNT_DIR
fi
}

destroy_component_rootfs_as_needed() {
cleanup_build_env

if [ $BUILD_TYPE == "--really-clean" ]; then
  if [ -e $LOCAL_ROOTFS_COMMON.lock ]; then
    rm $LOCAL_ROOTFS_COMMON.lock
  fi

  if [ -e $LOCAL_ROOTFS_COMMON.ext4 ]; then
    rm  $LOCAL_ROOTFS_COMMON.ext4
  fi

  LOCAL_BUILD_TYPE=--clean
  LOCAL_COMPONENT_ONLY_BUILDS=--all
fi
}

setup_build_env() {
if [ ! -e $LOCAL_ROOTFS_COMMON.ext4 ]; then
  echo "Cannot find chroot..."
  exit 1
fi

mkdir -p $LOCAL_ROOTFS_COMMON_MOUNT_DIR
sudo mount $LOCAL_ROOTFS_COMMON.ext4 $LOCAL_ROOTFS_COMMON_MOUNT_DIR/

if [ -e $LOCAL_ROOTFS_COMMON_MOUNT_DIR/log/common ]; then
  sudo rm -rf $LOCAL_ROOTFS_COMMON_MOUNT_DIR/log/common
fi

if [ -e $LOCAL_ROOTFS_COMMON_MOUNT_DIR/scripts/common ]; then
  sudo rm -rf $LOCAL_ROOTFS_COMMON_MOUNT_DIR/scripts/common
fi

sudo mkdir -p $LOCAL_ROOTFS_COMMON_MOUNT_DIR/scripts/common
sudo cp -v $LOCAL_PWD/scripts/common/*.sh $LOCAL_ROOTFS_COMMON_MOUNT_DIR/scripts/common/

sudo mkdir -p $LOCAL_ROOTFS_COMMON_MOUNT_DIR/build
sudo mkdir -p $LOCAL_ROOTFS_COMMON_MOUNT_DIR/log/common
sudo mount --rbind $SOURCE_PWD $LOCAL_ROOTFS_COMMON_MOUNT_DIR/build
sudo mount --rbind $BASE_PWD/build/log/common $LOCAL_ROOTFS_COMMON_MOUNT_DIR/log/common
}

building_component() {
component="${1}"
ls -a $LOCAL_ROOTFS_COMMON_MOUNT_DIR/scripts/common/
if sudo chroot $LOCAL_ROOTFS_COMMON_MOUNT_DIR/ /bin/bash /scripts/common/main.sh $LOCAL_BUILD_TYPE $component $BUILD_CHANNEL $BUILD_TARGET; then
  echo "Built------------" $component
else
  exit 1
fi
}

cd $LOCAL_PWD/images/
#Generate rootfs for common components.
destroy_component_rootfs_as_needed
generate_component_rootfs
setup_build_env

echo "Building components."
if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--x11" ]; then
  building_component "--x11"
fi

if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--wayland" ]; then
  building_component "--wayland"
fi

if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--drivers" ]; then
  building_component "--drivers"
fi

if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--demos" ]; then
  building_component "--demos"
fi

cleanup_build_env

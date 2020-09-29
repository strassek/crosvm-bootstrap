#! /bin/bash

# common.sh
# Generates base rootfs image which is used to create host and guest
# rootfs images.

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
LOCAL_ROOTFS_MOUNT_DIR=rootfs_base-temp

mkdir -p $BASE_PWD/build/images
mkdir -p $BASE_PWD/build/log/common

if bash common/scripts/common_checks_internal.sh $LOCAL_PWD $SOURCE_PWD --true --false $COMPONENT_TARGET $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET  $CREATE_BASE_IMAGE_ONLY; then
  echo “Preparing base rootfs image...”
else
  echo “Failed to find needed dependencies, exit status: $?”
  exit 1
fi

source $SCRIPTS_DIR/common/error_handler_internal.sh $LOG_DIR rootfs.log $LOCAL_PWD

destroy_base_rootfs_as_needed() {
if [ -e $LOCAL_ROOTFS_MOUNT_DIR ]; then
  if mount | grep $LOCAL_ROOTFS_MOUNT_DIR/build > /dev/null; then
    umount -l $LOCAL_ROOTFS_MOUNT_DIR/build
  fi

  if mount | grep $LOCAL_ROOTFS_MOUNT_DIR > /dev/null; then
    umount -l $LOCAL_ROOTFS_MOUNT_DIR
  fi

  rm -rf $LOCAL_ROOTFS_MOUNT_DIR
fi

if [ $BUILD_TYPE == "--really-clean" ]; then
  if [ -e $LOCAL_ROOTFS_BASE.lock ]; then
    rm $LOCAL_ROOTFS_BASE.lock
  fi

  if [ -e $LOCAL_ROOTFS_BASE.ext4 ]; then
  echo "destroying rootfs image----- \n";
    rm  $LOCAL_ROOTFS_BASE.ext4
  fi
fi
}

generate_base_rootfs() {
if [ -e $LOCAL_ROOTFS_BASE.ext4 ]; then
  echo "Base rootfs image already exists. Reusing it."
  return 0;
fi

if [ -e $LOCAL_ROOTFS_MOUNT_DIR ]; then
  rm -rf $LOCAL_ROOTFS_MOUNT_DIR
fi

if [ -e $LOCAL_ROOTFS_BASE.lock ]; then
  rm $LOCAL_ROOTFS_BASE.lock
fi

if [ -e $LOCAL_ROOTFS_BASE.ext4 ]; then
  rm $LOCAL_ROOTFS_BASE.ext4
fi

echo "Generating rootfs...."
dd if=/dev/zero of=$LOCAL_ROOTFS_BASE.ext4 bs=5000 count=1M
mkfs.ext4 $LOCAL_ROOTFS_BASE.ext4
mkdir $LOCAL_ROOTFS_MOUNT_DIR/
mount $LOCAL_ROOTFS_BASE.ext4 $LOCAL_ROOTFS_MOUNT_DIR/
debootstrap --arch=amd64 buster $LOCAL_ROOTFS_MOUNT_DIR/

mkdir -p $LOCAL_ROOTFS_MOUNT_DIR/scripts/common
cp $LOCAL_PWD/scripts/common/*.sh $LOCAL_ROOTFS_MOUNT_DIR/scripts/common/
mkdir -p $LOCAL_ROOTFS_MOUNT_DIR/config/
cp -v $LOCAL_PWD/config/*.env $LOCAL_ROOTFS_MOUNT_DIR/config

mkdir -p $LOCAL_ROOTFS_MOUNT_DIR/proc
mkdir -p $LOCAL_ROOTFS_MOUNT_DIR/dev/shm
mkdir -p $LOCAL_ROOTFS_MOUNT_DIR/dev/pts
mount -t proc /proc $LOCAL_ROOTFS_MOUNT_DIR/proc
mount -o bind /dev/shm $LOCAL_ROOTFS_MOUNT_DIR/dev/shm
mount -o bind /dev/pts $LOCAL_ROOTFS_MOUNT_DIR/dev/pts

echo "Installing needed system packages for host and vm"
chroot $LOCAL_ROOTFS_MOUNT_DIR/ /bin/bash /scripts/common/system_packages_internal.sh
echo "Configuring default user"
chroot $LOCAL_ROOTFS_MOUNT_DIR/ /bin/bash /scripts/common/default_user.sh
LOCAL_BUILD_CHANNEL=stable
LOCAL_BUILD_TARGET=release
if [ $BUILD_CHANNEL == "--dev" ]; then
  LOCAL_BUILD_CHANNEL=dev
fi

if [ $BUILD_TARGET == "--debug" ]; then
  LOCAL_BUILD_TARGET=debug
fi

echo "Configuring Run time settings"
chroot $LOCAL_ROOTFS_MOUNT_DIR/ /bin/bash /scripts/common/run_time_settings.sh test $LOCAL_BUILD_CHANNEL $LOCAL_BUILD_TARGET
echo "Rootfs ready..."
echo "rootfs generated" > $LOCAL_ROOTFS_BASE.lock
echo "Cleaningup build env..."
if mount | grep $LOCAL_ROOTFS_MOUNT_DIR/build > /dev/null; then
  umount -l $LOCAL_ROOTFS_MOUNT_DIR/build
fi

umount -l $LOCAL_ROOTFS_MOUNT_DIR/proc
umount -l $LOCAL_ROOTFS_MOUNT_DIR/dev/shm
umount -l $LOCAL_ROOTFS_MOUNT_DIR/dev/pts

if mount | grep $LOCAL_ROOTFS_MOUNT_DIR > /dev/null; then
  umount -l $LOCAL_ROOTFS_MOUNT_DIR
fi

rm -rf $LOCAL_ROOTFS_MOUNT_DIR
}

cd $LOCAL_PWD/images/
destroy_base_rootfs_as_needed
generate_base_rootfs

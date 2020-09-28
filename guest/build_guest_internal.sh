#! /bin/bash

# build-guest-internal.sh
# Builds xserver and sommelier packages needed on guest side.

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
LOG_DIR=$LOCAL_PWD/log/guest
SCRIPTS_DIR=$LOCAL_PWD/scripts/guest

# Rootfs Names
LOCAL_ROOTFS_GUEST=rootfs_guest
LOCAL_ROOTFS_GUEST_MOUNT_DIR=rootfs_guest-temp
LOCAL_ROOTFS_COMMON=rootfs_common

mkdir -p $LOG_DIR
 
if bash guest/scripts/common_checks_internal.sh $LOCAL_PWD --true --false $COMPONENT_TARGET $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET; then
  echo “Preparing to build vm...”
else
  echo “Failed to find needed dependencies, exit status: $?”
  exit 1
fi

source $SCRIPTS_DIR/error_handler_internal.sh $LOG_DIR guest.log $LOCAL_PWD

generate_guest_rootfs() {
if [ -e $LOCAL_ROOTFS_GUEST.ext4 ]; then
  echo "guest rootfs image already exists. Reusing it."
  return 0;
fi

if [ ! -e $LOCAL_ROOTFS_COMMON.ext4 ]; then
  echo "Common rootfs image doesn't exists. Please build it first."
  exit 1
fi

echo "Preparing rootfs image for guest..."
cp -rf $LOCAL_ROOTFS_COMMON.ext4 $LOCAL_ROOTFS_GUEST.ext4
mkdir -p $LOCAL_ROOTFS_GUEST_MOUNT_DIR
mount $LOCAL_ROOTFS_GUEST.ext4 $LOCAL_ROOTFS_GUEST_MOUNT_DIR/

mkdir -p $LOCAL_ROOTFS_GUEST_MOUNT_DIR/scripts/guest/
cp $LOCAL_PWD/scripts/guest/*.sh $LOCAL_ROOTFS_GUEST_MOUNT_DIR/scripts/guest/

cp -rvf $LOCAL_PWD/config/default-config/guest/* $LOCAL_ROOTFS_GUEST_MOUNT_DIR/

echo "enabling needed services"
chroot $LOCAL_ROOTFS_GUEST_MOUNT_DIR/ /bin/bash /scripts/guest/services_internal.sh

echo "Rootfs image for guest is ready. Preparing to compile guest packages..."
umount -l $LOCAL_ROOTFS_GUEST_MOUNT_DIR
if [ ! -e .${LOCAL_ROOTFS_GUEST}_lock ]; then
  echo "rootfs generated" > .${LOCAL_ROOTFS_GUEST}_lock
fi
}

cleanup_build_env() {
if [ -e $LOCAL_ROOTFS_GUEST_MOUNT_DIR ]; then
  if mount | grep $LOCAL_ROOTFS_GUEST_MOUNT_DIR/build > /dev/null; then
    umount -l $LOCAL_ROOTFS_GUEST_MOUNT_DIR/build
  fi
  
  if mount | grep $LOCAL_ROOTFS_GUEST_MOUNT_DIR/log/guest > /dev/null; then
    umount -l $LOCAL_ROOTFS_GUEST_MOUNT_DIR/log/guest
  fi
        
  if mount | grep $LOCAL_ROOTFS_GUEST_MOUNT_DIR > /dev/null; then
    umount -l $LOCAL_ROOTFS_GUEST_MOUNT_DIR
  fi

  rm -rf $LOCAL_ROOTFS_GUEST_MOUNT_DIR
fi
}

destroy_guest_rootfs_as_needed() {
cleanup_build_env

if [ $BUILD_TYPE == "--really-clean" ]; then
  if [ -e .${LOCAL_ROOTFS_GUEST}_lock ]; then
    rm .${LOCAL_ROOTFS_GUEST}_lock
  fi
  
  if [ -e $LOCAL_PWD/images/$LOCAL_ROOTFS_GUEST.ext4 ]; then
    rm  $LOCAL_PWD/images/$LOCAL_ROOTFS_GUEST.ext4
  fi
  
  LOCAL_BUILD_TYPE=--clean
fi
}

setup_build_env() {
if [ ! -e $LOCAL_ROOTFS_GUEST.ext4 ]; then
  echo "Cannot find chroot..."
  exit 1
fi

mkdir -p $LOCAL_ROOTFS_GUEST_MOUNT_DIR
mount $LOCAL_ROOTFS_GUEST.ext4 $LOCAL_ROOTFS_GUEST_MOUNT_DIR/

if [ ! -e $LOCAL_ROOTFS_GUEST_MOUNT_DIR/scripts/guest ]; then
  rm -rf $LOCAL_ROOTFS_GUEST_MOUNT_DIR/scripts/guest
fi

if [ ! -e $LOCAL_ROOTFS_GUEST_MOUNT_DIR/log/guest ]; then
  rm -rf $LOCAL_ROOTFS_GUEST_MOUNT_DIR/log/guest
fi

mkdir -p $LOCAL_ROOTFS_GUEST_MOUNT_DIR/build
mkdir -p $LOCAL_ROOTFS_GUEST_MOUNT_DIR/scripts/guest
mkdir -p $LOCAL_ROOTFS_GUEST_MOUNT_DIR/log/guest
mount --rbind $SOURCE_PWD $LOCAL_ROOTFS_GUEST_MOUNT_DIR/build
mount --rbind $BASE_PWD/build/log/guest $LOCAL_ROOTFS_GUEST_MOUNT_DIR/log/guest
cp $LOCAL_PWD/scripts/guest/*.sh $LOCAL_ROOTFS_GUEST_MOUNT_DIR/scripts/guest/ 
}

# Handle base builds
mkdir -p $LOCAL_PWD/images
cd $LOCAL_PWD/images
destroy_guest_rootfs_as_needed

# Generate rootfs if needed
generate_guest_rootfs

setup_build_env

echo "Building guest."
if chroot $LOCAL_ROOTFS_GUEST_MOUNT_DIR/ /bin/bash /scripts/guest/main.sh $LOCAL_BUILD_TYPE --all $BUILD_CHANNEL $BUILD_TARGET; then
  echo "Built------------" $component
else
  exit 1
fi

cleanup_build_env

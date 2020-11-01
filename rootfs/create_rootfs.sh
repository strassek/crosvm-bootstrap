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
COMPONENT_TARGET=${2:-"common"}
BUILD_TYPE=${3:-"--clean"} # Possible values: --clean, --incremental --really-clean
SIZE=${4:-"5000"}

LOCAL_PWD=$BASE_PWD/build
SOURCE_PWD=$BASE_PWD/source
LOCAL_BUILD_TYPE=$BUILD_TYPE
LOG_DIR=$BASE_PWD/build/log/$COMPONENT_TARGET
SCRIPTS_DIR=$LOCAL_PWD/scripts
LOCAL_USER=test

# Rootfs Names
LOCAL_ROOTFS_BASE=rootfs_host
LOCAL_ROOTFS_MOUNT_DIR=rootfs_host-temp

if [[ "$COMPONENT_TARGET" == "guest" ]]; then
  LOCAL_ROOTFS_BASE=rootfs_guest
  LOCAL_ROOTFS_MOUNT_DIR=rootfs_guest-temp
fi

if [[ "$COMPONENT_TARGET" == "game-fast" ]]; then
  LOCAL_ROOTFS_BASE=rootfs_game_fast
  LOCAL_ROOTFS_MOUNT_DIR=rootfs_game_fast-temp
fi

mkdir -p $BASE_PWD/build/images
mkdir -p $BASE_PWD/build/log/$COMPONENT_TARGET

source $SCRIPTS_DIR/$COMPONENT_TARGET/error_handler_internal.sh $LOG_DIR rootfs.log $LOCAL_PWD

destroy_base_rootfs_as_needed() {
if [ -e $LOCAL_ROOTFS_MOUNT_DIR ]; then
  if mount | grep $LOCAL_ROOTFS_MOUNT_DIR/build > /dev/null; then
    sudo umount -l $LOCAL_ROOTFS_MOUNT_DIR/build
  fi

  if mount | grep $LOCAL_ROOTFS_MOUNT_DIR > /dev/null; then
    sudo umount -l $LOCAL_ROOTFS_MOUNT_DIR
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

echo "Generating rootfs...."
dd if=/dev/zero of=$LOCAL_ROOTFS_BASE.ext4 bs=$SIZE count=1M
mkfs.ext4 $LOCAL_ROOTFS_BASE.ext4
mkdir $LOCAL_ROOTFS_MOUNT_DIR/

sudo mount $LOCAL_ROOTFS_BASE.ext4 $LOCAL_ROOTFS_MOUNT_DIR/
sudo $LOCAL_PWD/rootfs/debootstrap --arch=amd64 --unpack-tarball=$LOCAL_PWD/rootfs/rootfs_container.tar focal $LOCAL_ROOTFS_MOUNT_DIR/

sudo mount -t proc /proc $LOCAL_ROOTFS_MOUNT_DIR/proc
sudo mount -o bind /dev/shm $LOCAL_ROOTFS_MOUNT_DIR/dev/shm
sudo mount -o bind /dev/pts $LOCAL_ROOTFS_MOUNT_DIR/dev/pts

sudo mkdir -p $LOCAL_ROOTFS_MOUNT_DIR/scripts/$COMPONENT_TARGET
sudo mkdir -p $LOCAL_ROOTFS_MOUNT_DIR/scripts/rootfs
sudo cp -rpvf $LOCAL_PWD/scripts/$COMPONENT_TARGET/*.sh $LOCAL_ROOTFS_MOUNT_DIR/scripts/$COMPONENT_TARGET/
sudo cp -rpvf $BASE_PWD/rootfs/*.sh $LOCAL_ROOTFS_MOUNT_DIR/scripts/rootfs/

sudo chroot $LOCAL_ROOTFS_MOUNT_DIR/ /bin/bash /scripts/rootfs/basic_setup.sh

sudo cp -rpvf $LOCAL_PWD/config/default-config/common/* $LOCAL_ROOTFS_MOUNT_DIR/

echo "Installing needed system packages...."
sudo chroot $LOCAL_ROOTFS_MOUNT_DIR/ /bin/bash -c "su - $LOCAL_USER -c /scripts/rootfs/common_system_packages.sh"

sudo chroot $LOCAL_ROOTFS_MOUNT_DIR/ /bin/bash /scripts/$COMPONENT_TARGET/system_packages_internal.sh

if [[ "$COMPONENT_TARGET" == "guest" ]]; then
  sudo cp -rpvf $LOCAL_PWD/config/default-config/guest/* $LOCAL_ROOTFS_MOUNT_DIR/
  sudo chroot $LOCAL_ROOTFS_MOUNT_DIR/ /bin/bash /scripts/$COMPONENT_TARGET/container_settings.sh
  sudo cp $BASE_PWD/guest/serial-getty@.service $LOCAL_ROOTFS_MOUNT_DIR/lib/systemd/system/
fi

if [[ "$COMPONENT_TARGET" == "game-fast" ]]; then
  sudo cp -rpvf $LOCAL_PWD/config/default-config/container/* $LOCAL_ROOTFS_MOUNT_DIR/
  sudo rm $LOCAL_ROOTFS_MOUNT_DIR/etc/profile.d/system-compositor.sh

  echo "enabling needed services"
  sudo chroot $LOCAL_ROOTFS_MOUNT_DIR/ /bin/bash -c "su - $LOCAL_USER -c /scripts/$COMPONENT_TARGET/services_internal.sh"

  sudo cp -rpvf $LOCAL_PWD/config/default-config/container/etc/profile.d/system-compositor.sh $LOCAL_ROOTFS_MOUNT_DIR/etc/profile.d/
fi

echo "Rootfs ready..."
echo "rootfs generated" > $LOCAL_ROOTFS_BASE.lock
echo "Cleaningup build env..."
if mount | grep $LOCAL_ROOTFS_MOUNT_DIR/build > /dev/null; then
  sudo umount -l $LOCAL_ROOTFS_MOUNT_DIR/build
fi

sudo umount -l $LOCAL_ROOTFS_MOUNT_DIR/proc
sudo umount -l $LOCAL_ROOTFS_MOUNT_DIR/dev/shm
sudo umount -l $LOCAL_ROOTFS_MOUNT_DIR/dev/pts

if mount | grep $LOCAL_ROOTFS_MOUNT_DIR > /dev/null; then
  sudo umount -l $LOCAL_ROOTFS_MOUNT_DIR
fi

rm -rf $LOCAL_ROOTFS_MOUNT_DIR
}

if [[ "$COMPONENT_TARGET" == "game-fast" ]] || [[ "$COMPONENT_TARGET" == "host" ]]; then
  cd $LOCAL_PWD/containers/
else
  cd $LOCAL_PWD/images/
fi

destroy_base_rootfs_as_needed
generate_base_rootfs

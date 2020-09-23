#! /bin/bash

# run-rootfs-builder.sh [USERNAME PASSWORD CONFIG_FILE MOUNT_POINT]
# Generate debian rootfs image using specified config file and mounted in the
# container at the specified path (should match mountPoint specified in json file)

INITIAL_BUILD_SETUP=$1
LOCAL_PWD=${2}
LOCAL_SOURCE_PWD=${3}
MOUNT_POINT=${4}

echo "main_rootfs: Recieved Arguments...."
echo "INITIAL_BUILD_SETUP:" $INITIAL_BUILD_SETUP
echo "LOCAL_PWD:" $LOCAL_PWD
echo "LOCAL_SOURCE_PWD:" $LOCAL_SOURCE_PWD
echo "MOUNT_POINT:" $MOUNT_POINT
echo "--------------------------"

LOCAL_DIRECTORY_PREFIX=$LOCAL_PWD
LOCAL_SRC_CONFIG_FILE="source.json"
LOCAL_CONFIG_FILE="image.json"
LOG_DIR=$LOCAL_DIRECTORY_PREFIX/output/component_log
LOCAL_FORCE_SOURCE_IMAGE_DELETION=--false
LOCAL_FORCE_ROOTFS_DELETION=--true

if [ $INITIAL_BUILD_SETUP == "--create-source-image-only" ]; then
  LOCAL_FORCE_ROOTFS_DELETION="--false"
fi

if [ $INITIAL_BUILD_SETUP == "--create-source-image-only" ]; then
  LOCAL_FORCE_SOURCE_DELETION="--true"
  if [ -e $LOCAL_SOURCE_PWD/source/source.ext4 ]; then
    echo "Source image already exists. Please check." $PWD
    exit 1;
  fi
  
  if [ -e $LOCAL_DIRECTORY_PREFIX/output/rootfs.ext4 ]; then
    echo "Source image already exists. Please check." $PWD
    exit 1;
  fi
fi

echo "main_rootfs: Using Arguments...."
echo "LOCAL_DIRECTORY_PREFIX:" $LOCAL_DIRECTORY_PREFIX
echo "LOCAL_SRC_CONFIG_FILE:" $LOCAL_SRC_CONFIG_FILE
echo "LOCAL_CONFIG_FILE:" $LOCAL_CONFIG_FILE
echo "LOG_DIR:" $LOG_DIR
echo "LOCAL_FORCE_SOURCE_IMAGE_DELETION:" $LOCAL_FORCE_SOURCE_IMAGE_DELETION
echo "--------------------------"

source $LOCAL_DIRECTORY_PREFIX/output/scripts/error_handler_internal.sh $LOG_DIR $LOCAL_DIRECTORY_PREFIX main_rootfs_err.log $LOCAL_FORCE_ROOTFS_DELETION $LOCAL_FORCE_SOURCE_IMAGE_DELETION $LOCAL_SOURCE_PWD $MOUNT_POINT

if [ $INITIAL_BUILD_SETUP != "--none" ]  && [ $INITIAL_BUILD_SETUP != "--create-rootfs-image-only" ] && [ $INITIAL_BUILD_SETUP != "--create-source-image-only" ] && [ $INITIAL_BUILD_SETUP != "--setup-initial-environment" ] && [ $INITIAL_BUILD_SETUP != "--bootstrap" ]; then
  echo "Invalid INITIAL_BUILD_SETUP. Please check build_options.txt file for supported combinations."
  exit 1
fi

echo "Directory Prefix being used:" $LOCAL_DIRECTORY_PREFIX

mount() {
mount_system_dir="${1}"
mount_source="${2}"
mount_output="${3}"
if bash $LOCAL_DIRECTORY_PREFIX/output/scripts/mount_internal.sh $mount_system_dir $mount_source $mount_output $LOCAL_PWD $LOCAL_SOURCE_PWD $MOUNT_POINT
  then
  echo "Mount succeeded...."
else
  echo "Failed to Mount..."
  echo "Removing rootfs image. Please run ./build.sh with same build options again."
  rm -rf $LOCAL_DIRECTORY_PREFIX/output/rootfs.ext4
  exit 1
fi
}

unmount() {
unmount_system_dir="${1}"
unmount_source="${2}"
unmount_output="${3}"
if bash $LOCAL_DIRECTORY_PREFIX/output/scripts/unmount_internal.sh $unmount_system_dir $unmount_source $unmount_output $LOCAL_PWD $MOUNT_POINT
then
  echo "unmounted all directories...."
else
  echo "Failed to unmount..."
  exit 1
fi
}

# Generate initial rootfs image.
if [ $INITIAL_BUILD_SETUP == "--create-rootfs-image-only" ]; then
  echo "Generating rootfs image"
  python3 $LOCAL_DIRECTORY_PREFIX/output/scripts/create_image_internal.py --spec  $LOCAL_DIRECTORY_PREFIX/config/$LOCAL_CONFIG_FILE --create

  if [ ! -e $LOCAL_DIRECTORY_PREFIX/output/rootfs.ext4 ]; then
    echo "Failed to create Rootfs image."
    exit 1;
  fi

  exit 0;
fi

if [ $INITIAL_BUILD_SETUP == "--bootstrap" ]; then
  if [ ! -e $LOCAL_DIRECTORY_PREFIX/output/rootfs.ext4 ]; then
    echo "Failed to create Rootfs image."
    exit 1;
  fi

  echo "Bootstrapping debian userspace"
  mount "--false" "--false" "--false"
  debootstrap --arch=amd64 testing $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT
  unmount "--false" "--false" "--false"
  echo "Bootstrap succeeded...."
  exit 0;
fi

# We should have mounted $LOCAL_DIRECTORY_PREFIX/output/scripts to /build/output/scripts in mount_internal.sh
if [ $INITIAL_BUILD_SETUP == "--setup-initial-environment" ]; then
  mount "--true" "--false" "--true"
  echo "Copying user configuration script..."
  mkdir -p $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/deploy/config
  cp $LOCAL_DIRECTORY_PREFIX/output/scripts/create_users_internal.py $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/deploy/
  cp $LOCAL_DIRECTORY_PREFIX/config/users.json $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/deploy/config/
  if [ ! -e  $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/deploy/config/users.json ]; then
    echo "User configuration file not found."
    unmount "--true" "--false" "--true"
    exit 1
  fi

  if [ ! -e  $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/deploy/create_users_internal.py ]; then
    echo "User configuration file not found."
    unmount "--true" "--false" "--true"
    exit 1
  fi

  echo "Installing needed dependencies..."
  chroot $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/ ls -a  /build/output/scripts/
  chroot $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/ /bin/bash /build/output/scripts/system_packages_internal.sh

  echo "Configuring the user..."
  chroot $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/ ls -a /deploy
  chroot $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/ python3 /deploy/create_users_internal.py --spec /deploy/config/users.json false
  echo "Configuring rootfs..."
  cp -rvf $LOCAL_DIRECTORY_PREFIX/config/guest/* $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/
  chroot $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/ ls -a usr/lib/systemd/user/
  echo "Enabling Needed Services..."
  chroot $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/ python3 /deploy/create_users_internal.py --spec /deploy/config/users.json true
  rm -rf $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/deploy/
  
  echo "Setup Rust and Cargo........."
  chroot $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/ /bin/bash /build/output/scripts/setup_rust.sh
  unmount "--true" "--false" "--true"
  exit 0;
fi

if [ $INITIAL_BUILD_SETUP == "--create-source-image-only" ]; then
  echo "Generating source image" $PWD
  if [ -e $LOCAL_SOURCE_PWD/source/source.ext4 ]; then
    echo "Source image already exists. Please check." $PWD
    exit 1;
  fi
  
  if [ ! -e $LOCAL_DIRECTORY_PREFIX/output/rootfs.ext4 ]; then
    echo "Cannot find Rootfs image."
    exit 1;
  fi
  
  python3 $LOCAL_DIRECTORY_PREFIX/output/scripts/create_image_internal.py --spec $LOCAL_DIRECTORY_PREFIX/config/$LOCAL_SRC_CONFIG_FILE --create

  if [ ! -e $LOCAL_SOURCE_PWD/source/source.ext4 ]; then
    echo "Failed to create Source image." $PWD
    exit 1;
  fi

  echo "Cloning code..."
  mount "--true" "--true" "--true"
  chroot $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/ /bin/bash /build/output/scripts/sync_code_internal.sh
  unmount "--true" "--true" "--true"
  exit 0;
fi

echo "Done!"

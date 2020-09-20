#! /bin/bash

# run-rootfs-builder.sh [USERNAME PASSWORD CONFIG_FILE MOUNT_POINT]
# Generate debian rootfs image using specified config file and mounted in the
# container at the specified path (should match mountPoint specified in json file)

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

BUILD_ENVIRONMENT=$1
INITIAL_BUILD_SETUP=$2
MOUNT_POINT=${3}

echo "Recieved Arguments...."
echo "BUILD_ENVIRONMENT:" $BUILD_ENVIRONMENT
echo "INITIAL_BUILD_SETUP:" $INITIAL_BUILD_SETUP
echo "MOUNT_POINT:" $MOUNT_POINT
echo "--------------------------"

LOCAL_DIRECTORY_PREFIX=/build
LOCAL_SRC_CONFIG_FILE="source.json"
LOCAL_CONFIG_FILE="image.json"

if [ $BUILD_ENVIRONMENT != "--chroot" ] && [ $BUILD_ENVIRONMENT != "--docker" ]; then
  echo "Invalid Build Environment. Valid Values:--chroot, --docker"
  exit 1
fi

if [ $INITIAL_BUILD_SETUP != "--none" ]  && [ $INITIAL_BUILD_SETUP != "--create-rootfs-image-only" ] && [ $INITIAL_BUILD_SETUP != "--create-source-image-only" ] && [ $INITIAL_BUILD_SETUP != "--setup-initial-environment" ] && [ $INITIAL_BUILD_SETUP != "--bootstrap" ]; then
  echo "Invalid INITIAL_BUILD_SETUP. Please check build_options.txt file for supported combinations."
  exit 1
fi

if [ $BUILD_ENVIRONMENT == "--docker" ]; then
  LOCAL_DIRECTORY_PREFIX=/app
fi

echo "Directory Prefix being used:" $LOCAL_DIRECTORY_PREFIX

mount() {
mount_system_dir="${1}"
mount_source="${2}"
mount_output="${3}"
if bash $LOCAL_DIRECTORY_PREFIX/output/scripts/mount_internal.sh $mount_system_dir $mount_source $mount_output $BUILD_ENVIRONMENT $MOUNT_POINT
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
if bash $LOCAL_DIRECTORY_PREFIX/output/scripts/unmount_internal.sh $unmount_system_dir $unmount_source $unmount_output $BUILD_ENVIRONMENT $MOUNT_POINT
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
  echo "Generating source image"
  if [ -e $LOCAL_DIRECTORY_PREFIX/source/source.ext4 ]; then
    echo "Source image already exists. Please check." $PWD
    exit 1;
  fi
  
  if [ ! -e $LOCAL_DIRECTORY_PREFIX/output/rootfs.ext4 ]; then
    echo "Cannot find Rootfs image."
    exit 1;
  fi
  
  python3 $LOCAL_DIRECTORY_PREFIX/output/scripts/create_image_internal.py --spec $LOCAL_DIRECTORY_PREFIX/config/$LOCAL_SRC_CONFIG_FILE --create

  if [ ! -e $LOCAL_DIRECTORY_PREFIX/source/source.ext4 ]; then
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

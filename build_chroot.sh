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

INITIAL_BUILD_SETUP=${1:-"--none"}
BUILD_TYPE=${2:-"--clean"} # Possible values: --clean, --incremental --really-clean
COMPONENT_ONLY_BUILDS=${3:-"--all"}
TARGET_ARCH=${4:-"--all"}
SYNC_SOURCE=${5:-"--false"} # Possible values: --true, --false
BUILD_CHANNEL=${6:-"--stable"} # Possible values: --dev, --stable, --all
BUILD_TARGET=${7:-"--release"} # Possible values: --release, --debug, --all
UPDATE_SYSTEM=${8:-"--false"} # Possible values: --true, --false
MOUNT_POINT=${9:-"mount"}

LOCAL_PWD=$PWD/build
SOURCE_PWD=$PWD
LOCAL_BUILD_TYPE=$BUILD_TYPE
LOCAL_COMPONENT_ONLY_BUILDS=$COMPONENT_ONLY_BUILDS
LOCAL_INITIAL_BUILD_SETUP=$INITIAL_BUILD_SETUP
LOCAL_SYNC_SOURCE=$SYNC_SOURCE

mkdir -p $PWD/source
mkdir -p $LOCAL_PWD

if bash scripts/common_checks_internal.sh $LOCAL_PWD $SOURCE_PWD --true --false $INITIAL_BUILD_SETUP $BUILD_TYPE $COMPONENT_ONLY_BUILDS $TARGET_ARCH $SYNC_SOURCE $BUILD_CHANNEL $BUILD_TARGET $UPDATE_SYSTEM; then
  echo “Preparing docker...”
else
  echo “Failed to find needed dependencies, exit status: $?”
  exit 1
fi

if [ $LOCAL_INITIAL_BUILD_SETUP == "--rebuild-rootfs" ]; then
# Remove any old rootfs images
echo "Checking for existing rootfs images."
  if [ -e $LOCAL_PWD/output/rootfs.ext4 ]; then
    echo "Destroyed rootfs image."
    rm $LOCAL_PWD/output/rootfs.ext4;
  else
    echo "No pre-existing rootfs image exist."
  fi

  if [ -e $LOCAL_PWD/output/dev ]; then
    rm -rf $LOCAL_PWD/output/dev;
  fi

  if [ -e $LOCAL_PWD/output/stable ]; then
    rm -rf $LOCAL_PWD/output/stable;
  fi
fi

if [ $LOCAL_INITIAL_BUILD_SETUP == "--recreate-source-image-only" ]; then
# Remove any old rootfs images
  if [ -e $SOURCE_PWD/source/source.ext4 ]; then
    rm $SOURCE_PWD/source/source.ext4;
  fi
fi

cd $LOCAL_PWD
echo $PWD

building_rootfs() {
component="${1}"
if [ $component == "--create-source-image-only" ]; then
  cd $SOURCE_PWD
fi
$LOCAL_PWD/output/scripts/main_rootfs.sh $component $LOCAL_PWD $SOURCE_PWD $MOUNT_POINT
if [ $component == "--create-source-image-only" ]; then
  cd SLOCAL_PWD
fi
}

if [ ! -e $LOCAL_PWD/output/rootfs.ext4 ]; then
  building_rootfs "--create-rootfs-image-only"
  LOCAL_INITIAL_BUILD_SETUP="--bootstrap"
fi

if [ $LOCAL_INITIAL_BUILD_SETUP == "--bootstrap" ]; then
  echo "Bootstrap Debian...."
  building_rootfs "--bootstrap"
  LOCAL_INITIAL_BUILD_SETUP="--setup-initial-environment"
fi

if [ $LOCAL_INITIAL_BUILD_SETUP == "--setup-initial-environment" ]; then
  echo "Setting up initial environment."
  building_rootfs "--setup-initial-environment"
  LOCAL_BUILD_TYPE="--really-clean"
fi

if [ ! -e $SOURCE_PWD/source/source.ext4 ]; then
  echo "Setting up initial source image."
  building_rootfs "--create-source-image-only"
  LOCAL_BUILD_TYPE="--really-clean"
  LOCAL_SYNC_SOURCE="--false"
fi

if [ $LOCAL_BUILD_TYPE == "--really-clean" ]; then
  LOCAL_COMPONENT_ONLY_BUILDS="--all"
fi

# Handle component builds
echo "Building components."
building_component() {
component="${1}"
output/scripts/main.sh $LOCAL_BUILD_TYPE $component $TARGET_ARCH $LOCAL_SYNC_SOURCE $BUILD_CHANNEL $BUILD_TARGET $UPDATE_SYSTEM $LOCAL_PWD $SOURCE_PWD $MOUNT_POINT

LOCAL_SYNC_SOURCE="--false"
UPDATE_SYSTEM="--false"
}

if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ]; then
  building_component "--x11"
  building_component "--wayland"
fi

if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--drivers" ]; then
  building_component "--drivers"
fi

if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--kernel" ]; then
  building_component "--kernel"
fi

if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--vm" ]; then
  building_component "--vm"
fi

if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--demos" ]; then
  building_component "--demos"
fi

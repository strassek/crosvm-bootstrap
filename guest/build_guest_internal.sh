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
INITIAL_BUILD_SETUP=${2:-"--none"}
BUILD_TYPE=${3:-"--clean"} # Possible values: --clean, --incremental --really-clean
COMPONENT_ONLY_BUILDS=${4:-"--all"}
BUILD_CHANNEL=${5:-"--stable"} # Possible values: --dev, --stable, --all
BUILD_TARGET=${6:-"--release"} # Possible values: --release, --debug, --all
CREATE_BASE_IMAGE_ONLY=${7:-"--false"} # Possible values: --false, --true

LOCAL_PWD=$BASE_PWD/build
SOURCE_PWD=$BASE_PWD/source
LOCAL_BUILD_TYPE=$BUILD_TYPE
LOCAL_COMPONENT_ONLY_BUILDS=$COMPONENT_ONLY_BUILDS
LOCAL_INITIAL_BUILD_SETUP=$INITIAL_BUILD_SETUP
LOG_DIR=$BASE_PWD/build/log/guest
SCRIPTS_DIR=$LOCAL_PWD/scripts

mkdir -p $LOCAL_PWD/output
 
if bash guest/scripts/common_checks_internal.sh $LOCAL_PWD $SOURCE_PWD --true --false $INITIAL_BUILD_SETUP $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET  $CREATE_BASE_IMAGE_ONLY; then
  echo “Preparing docker...”
else
  echo “Failed to find needed dependencies, exit status: $?”
  exit 1
fi

source $SCRIPTS_DIR/guest/error_handler_internal.sh $LOG_DIR guest.log $LOCAL_PWD

cleanup_build_env() {
echo "cleanup---"
if [ -e user-temp ]; then
  if mount | grep user-temp/build > /dev/null; then
    umount -l user-temp/build
  fi
  
  if mount | grep user-temp/log > /dev/null; then
    umount -l user-temp/log
  fi
        
  if mount | grep user-temp > /dev/null; then
    umount -l user-temp
  fi

  rm -rf user-temp
fi
echo "cleanup done---"
}

destroy_rootfs_as_needed() {
if [ $INITIAL_BUILD_SETUP == "--none" ]; then
  return;
fi

cleanup_build_env

if [ $INITIAL_BUILD_SETUP == "--rebuild-all" ]; then
  if [ -e $LOCAL_PWD/images/rootfs.ext4 ]; then
  echo "destroy_docker_images1---"
    rm  $LOCAL_PWD/images/rootfs.ext4
  fi
fi
echo "destroy_docker_images---"
}

generate_rootfs() {
if [ -e $LOCAL_PWD/images/rootfs.ext4 ]; then
  echo "rootfs image already exists. Reusing it."
  return 0;
fi
    
echo "Generating rootfs image..."

if [ -e user-temp ]; then
  rm -rf user-temp
fi
    
dd if=/dev/zero of=rootfs.ext4 bs=3000 count=1M
mkfs.ext4 rootfs.ext4
mkdir user-temp/
mount rootfs.ext4 user-temp/
debootstrap --arch=amd64 buster user-temp/
    
echo "Configuring rootfs..."
cp -rvf $LOCAL_PWD/config/default-config/guest/* user-temp/
    
mkdir -p user-temp/scripts/
cp $LOCAL_PWD/scripts/guest/*.sh user-temp/scripts/

mkdir -p user-temp/config/
cp -v $LOCAL_PWD/config/*.env user-temp/config

echo "Installing needed system packages inside vm"
chroot user-temp/ /bin/bash /scripts/system_packages_internal.sh
echo "enabling needed services"
chroot user-temp/ /bin/bash /scripts/services_internal.sh
echo "Configuring default user"
chroot user-temp/ /bin/bash /scripts/default_user.sh
LOCAL_BUILD_CHANNEL=stable
LOCAL_BUILD_TARGET=release
if [ $BUILD_CHANNEL == "--dev" ]; then
  LOCAL_BUILD_CHANNEL=dev
fi
    
if [ $BUILD_TARGET == "--debug" ]; then
  LOCAL_BUILD_TARGET=debug
fi
    
chroot user-temp/ /bin/bash /scripts/run_time_settings.sh test $LOCAL_BUILD_CHANNEL $LOCAL_BUILD_TARGET
mkdir -p user-temp/build
}

setup_build_env() {
if [ ! -e user-temp ]; then
  echo "Cannot find chroot..."
  exit 1
fi
if [ ! -e user-temp/scripts/ ]; then
  rm -rf user-temp/scripts/
fi

mkdir -p user-temp/scripts/
mount --rbind $SOURCE_PWD user-temp/build
mount --rbind $BASE_PWD/build/log/guest user-temp/log
}

setup_32build_env() {
cp $LOCAL_PWD/scripts/guest/*.sh user-temp/scripts/
}

setup_64build_env() {
cp $LOCAL_PWD/scripts/host/*.sh user-temp/scripts/
}

building_component() {
component="${1}"
if chroot user-temp/ /bin/bash /scripts/main.sh $LOCAL_BUILD_TYPE $component $BUILD_CHANNEL $BUILD_TARGET; then
  echo "Built------------" $component
else
  exit 1
fi
}

# Handle base builds
mkdir -p $LOCAL_PWD/images
cd $LOCAL_PWD/images
destroy_rootfs_as_needed
generate_rootfs

if [ $CREATE_BASE_IMAGE_ONLY == "--true" ]; then
  exit 0;
fi

setup_build_env

echo "Building components."
# 64 bit builds
setup_64build_env
if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--x11" ]; then
  building_component "--x11"
fi

if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--wayland" ]; then
  building_component "--wayland"
fi

if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--drivers" ]; then
  building_component "--drivers"
fi

# 32 bit builds
setup_64build_env
if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--x11" ]; then
  building_component "--x11"
fi

if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--wayland" ]; then
  building_component "--wayland"
fi

if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--drivers" ]; then
  building_component "--drivers"
fi

if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--guest" ]; then
  building_component "--guest"
fi

cleanup_build_env

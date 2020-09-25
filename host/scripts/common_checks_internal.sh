#! /bin/bash

# build-rootfs-builder-container.sh
# Set up build environment for docker container that generates Debian rootfs
# then calls docker build.

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

DIRECTORY_PREFIX=${1}
SOURCE_PWD=${2}
BUILD_CHECK=${3:-"--false"}
PARAM_CHECKS_ONLY=${4:-"--false"}
INITIAL_BUILD_SETUP=${5:-"--none"}
BUILD_TYPE=${6:-"--clean"} # Possible values: --clean, --incremental --really-clean
COMPONENT_ONLY_BUILDS=${7:-"--all"}
BUILD_CHANNEL=${8:-"--stable"} # Possible values: --dev, --stable, --all
BUILD_TARGET=${9:-"--release"} # Possible values: --release, --debug, --all
CREATE_BASE_IMAGE_ONLY=${10:-"--false"}

echo "common: Recieved Build Arguments...."
echo "DIRECTORY_PREFIX:" $DIRECTORY_PREFIX
echo "SOURCE_PWD:" $SOURCE_PWD
echo "BUILD_CHECK:" $BUILD_CHECK
echo "PARAM_CHECKS_ONLY:" $PARAM_CHECKS_ONLY
echo "INITIAL_BUILD_SETUP:" $INITIAL_BUILD_SETUP
echo "BUILD_TYPE:" $BUILD_TYPE
echo "COMPONENT_ONLY_BUILDS:" $COMPONENT_ONLY_BUILDS
echo "BUILD_CHANNEL:" $BUILD_CHANNEL
echo "BUILD_TARGET:" $BUILD_TARGET
echo "-------------------------------------"

if [ $PARAM_CHECKS_ONLY == "--false" ]; then
  echo "Copying latest build scripts"
  if [ -e $DIRECTORY_PREFIX/scripts/host ]; then
    rm -rf $DIRECTORY_PREFIX/scripts/host
  fi

  mkdir -p $DIRECTORY_PREFIX/scripts/host
  cp -rf host/scripts/*.* $DIRECTORY_PREFIX/scripts/host/
  
  if [ -e $DIRECTORY_PREFIX/docker/host/ ]; then
    rm -rf $DIRECTORY_PREFIX/docker/host/
  fi

  mkdir -p build/docker/host
  cp host/dockerfiles/base.dockerfile build/docker/host/Dockerfile.base
  cp host/dockerfiles/x11.dockerfile build/docker/host/Dockerfile.x11
  cp host/dockerfiles/wayland.dockerfile build/docker/host/Dockerfile.wayland
  cp host/dockerfiles/drivers.dockerfile build/docker/host/Dockerfile.drivers
  cp host/dockerfiles/demos.dockerfile build/docker/host/Dockerfile.demos
  cp host/dockerfiles/vm.dockerfile build/docker/host/Dockerfile.vm
fi

if [ $BUILD_CHECK == "--true" ]; then
  if [ $INITIAL_BUILD_SETUP != "--none" ]  && [ $INITIAL_BUILD_SETUP != "--rebuild-all" ] && [ $INITIAL_BUILD_SETUP != "--rebuild-x11" ] && [ $INITIAL_BUILD_SETUP != "--rebuild-wayland" ] && [ $INITIAL_BUILD_SETUP != "--rebuild-drivers" ] && [ $INITIAL_BUILD_SETUP != "--rebuild-demos" ] && [ $INITIAL_BUILD_SETUP != "--rebuild-vm" ]; then
    echo "Invalid INITIAL_BUILD_SETUP. Please check build_options.txt file for supported combinations."
    exit 1
  fi
  
  if [ $BUILD_TYPE != "--clean" ] && [ $BUILD_TYPE != "--incremental" ] && [ $BUILD_TYPE != "--really-clean" ]; then
    echo "Invalid Build Type. Valid Values:--clean, --incremental, --really-clean"
    exit 1
  fi

  if [ $COMPONENT_ONLY_BUILDS != "--x11" ] && [ $COMPONENT_ONLY_BUILDS != "--wayland" ]  && [ $COMPONENT_ONLY_BUILDS != "--drivers" ] && [ $COMPONENT_ONLY_BUILDS != "--kernel" ] && [ $COMPONENT_ONLY_BUILDS != "--demos" ] && [ $COMPONENT_ONLY_BUILDS != "--all" ] && [ $COMPONENT_ONLY_BUILDS != "--vm" ]; then
    echo "Invalid value for COMPONENT_ONLY_BUILDS. Please check build_options.txt file for supported combinations."
    exit 1
  fi

  if [ $BUILD_CHANNEL != "--dev" ] && [ $BUILD_CHANNEL != "--stable" ] && [ $BUILD_CHANNEL != "--all" ]; then
    echo "Invalid Build Channel. Valid Values: --dev, --stable, --all"
    exit 1
  fi

  if [ $BUILD_TARGET != "--release" ] && [ $BUILD_TARGET != "--debug" ] && [ $BUILD_TARGET != "--all" ]; then
   echo "Invalid Build Target. Valid Values: --release, --debug, --all"
   exit 1
  fi
  
  if [ $CREATE_BASE_IMAGE_ONLY != "--true" ] && [ $CREATE_BASE_IMAGE_ONLY != "--false" ]; then
   echo "Invalid value passed for CREATE_BASE_IMAGE_ONLY. Valid Values: --true, --false"
   exit 1
  fi
else
  echo "Failed to find valid sources. Please run check_source.sh script"
fi

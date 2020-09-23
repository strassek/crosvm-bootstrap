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
TARGET_ARCH=${8:-"--all"}
SYNC_SOURCE=${9:-"--false"} # Possible values: --true, --false
BUILD_CHANNEL=${10:-"--stable"} # Possible values: --dev, --stable, --all
BUILD_TARGET=${11:-"--release"} # Possible values: --release, --debug, --all
UPDATE_SYSTEM=${12:-"--false"} # Possible values: --true, --false

echo "common: Recieved Build Arguments...."
echo "DIRECTORY_PREFIX:" $DIRECTORY_PREFIX
echo "SOURCE_PWD:" $SOURCE_PWD
echo "BUILD_CHECK:" $BUILD_CHECK
echo "PARAM_CHECKS_ONLY:" $PARAM_CHECKS_ONLY
echo "INITIAL_BUILD_SETUP:" $INITIAL_BUILD_SETUP
echo "BUILD_TYPE:" $BUILD_TYPE
echo "COMPONENT_ONLY_BUILDS:" $COMPONENT_ONLY_BUILDS
echo "TARGET_ARCH:" $TARGET_ARCH
echo "SYNC_SOURCE:" $SYNC_SOURCE
echo "BUILD_CHANNEL:" $BUILD_CHANNEL
echo "BUILD_TARGET:" $BUILD_TARGET
echo "UPDATE_SYSTEM:" $UPDATE_SYSTEM
echo "-------------------------------------"

if [ $PARAM_CHECKS_ONLY != "--true" ]; then
  echo "Copying latest build scripts"
  if [ ! -e $DIRECTORY_PREFIX/output/scripts ]; then
    rm -rf $DIRECTORY_PREFIX/output/scripts
  fi

  mkdir -p $DIRECTORY_PREFIX/output/scripts
  cp -rf scripts/*.* $DIRECTORY_PREFIX/output/scripts/

  if [ ! -e $DIRECTORY_PREFIX/config ]; then
    rm -rf $DIRECTORY_PREFIX/config
  fi

  mkdir -p $DIRECTORY_PREFIX/config
  cp default-config/*.json $DIRECTORY_PREFIX/config
  cp -rf default-config/guest/ $DIRECTORY_PREFIX/config/guest
fi

if [ $BUILD_CHECK == "--true" ]; then
  if [ $INITIAL_BUILD_SETUP != "--none" ]  && [ $INITIAL_BUILD_SETUP != "--create-rootfs-image-only" ] && [ $INITIAL_BUILD_SETUP != "--create-source-image-only" ] && [ $INITIAL_BUILD_SETUP != "--setup-initial-environment" ] && [ $INITIAL_BUILD_SETUP != "--bootstrap" ]; then
    echo "Invalid INITIAL_BUILD_SETUP. Please check build_options.txt file for supported combinations."
    exit 1
  fi
  
  if [ $BUILD_TYPE != "--clean" ] && [ $BUILD_TYPE != "--incremental" ] && [ $BUILD_TYPE != "--really-clean" ]; then
    echo "Invalid Build Type. Valid Values:--clean, --incremental, --create-source-image-only --setup-initial-enviroment --really-clean"
    exit 1
  fi

  if [ $COMPONENT_ONLY_BUILDS != "--x11" ] && [ $COMPONENT_ONLY_BUILDS != "--wayland" ]  && [ $COMPONENT_ONLY_BUILDS != "--drivers" ] && [ $COMPONENT_ONLY_BUILDS != "--kernel" ] && [ $COMPONENT_ONLY_BUILDS != "--demos" ] && [ $COMPONENT_ONLY_BUILDS != "--all" ] && [ $COMPONENT_ONLY_BUILDS != "--vm" ]; then
    echo "Invalid value for COMPONENT_ONLY_BUILDS. Please check build_options.txt file for supported combinations."
    exit 1
  fi

  if [ $SYNC_SOURCE != "--true" ] && [ $SYNC_SOURCE != "--false" ]; then
    echo "Invalid request for updating channel. Valid Values: --true, --false"
    exit 1
  fi

  if [ $BUILD_CHANNEL != "--dev" ] && [ $BUILD_CHANNEL != "--stable" ] && [ $BUILD_CHANNEL != "--all" ]; then
    echo "Invalid Build Channel. Valid Values: --dev, --stable, --all"
    exit 1
  fi

  if [ $BUILD_TARGET != "--release" ] && [ $BUILD_TARGET != "--debug" ] && [ $BUILD_TARGET != "--all" ]; then
   echo "Invalid Build Channel. Valid Values: --release, --debug, --all"
   exit 1
  fi

  if [ $UPDATE_SYSTEM != "--true" ] && [ $UPDATE_SYSTEM != "--false" ]; then
    echo "Invalid request for updating system. Valid Values: --true, --false"
    exit 1
  fi

  if [ $TARGET_ARCH != "--all" ] && [ $TARGET_ARCH != "--x86_64" ] && [ $TARGET_ARCH != "--i386" ]; then
    echo "Invalid value for TARGET_ARCH2. Please check build_options.txt file for supported options."
    exit 1
  fi
else
  if [ ! -e $DIRECTORY_PREFIX/output/rootfs.ext4 ]; then
    echo "Unable to find rootfs.ext4 is not found. Please run build.sh with --rebuild-rootfs  to generate rootfs image first."
    exit 1
  fi

  if [ ! -e $SOURCE_PWD/source/source.ext4 ]; then
    echo "Unable to find source.ext4. Please run build.sh with --rebuild-rootfs  to generate rootfs image first."
    exit 1
  fi
fi

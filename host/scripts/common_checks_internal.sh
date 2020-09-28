#! /bin/bash

# build-rootfs-builder-container.sh
# Set up build environment for docker container that generates Debian rootfs
# then calls docker build.

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

DIRECTORY_PREFIX=${1}
BUILD_CHECK=${2:-"--false"}
PARAM_CHECKS_ONLY=${3:-"--false"}
COMPONENT_TARGET=${4:-"--none"}
BUILD_TYPE=${5:-"--clean"} # Possible values: --clean, --incremental --really-clean
COMPONENT_ONLY_BUILDS=${6:-"--all"}
BUILD_CHANNEL=${7:-"--stable"} # Possible values: --dev, --stable, --all
BUILD_TARGET=${8:-"--release"} # Possible values: --release, --debug, --all

echo "common: Recieved Build Arguments...."
echo "DIRECTORY_PREFIX:" $DIRECTORY_PREFIX
echo "BUILD_CHECK:" $BUILD_CHECK
echo "PARAM_CHECKS_ONLY:" $PARAM_CHECKS_ONLY
echo "COMPONENT_TARGET:" $COMPONENT_TARGET
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
fi

if [ $BUILD_CHECK == "--true" ]; then
  if [ $COMPONENT_TARGET != "--host" ]; then
    echo "Invalid COMPONENT_TARGET. Please check build_options.txt file for supported combinations."
    exit 1
  fi
  
  if [ $BUILD_TYPE != "--clean" ] && [ $BUILD_TYPE != "--incremental" ] && [ $BUILD_TYPE != "--really-clean" ]; then
    echo "Invalid Build Type. Valid Values:--clean, --incremental, --really-clean"
    exit 1
  fi

  if [ $COMPONENT_ONLY_BUILDS != "--all" ]; then
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
fi

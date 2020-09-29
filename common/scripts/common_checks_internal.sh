#! /bin/bash

# common_checks_internal.sh
# Checks that all inputs recieved can be handled by the build system.
# Copies scripts, config files at start of every build.

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

DIRECTORY_PREFIX=${1}
SOURCE_PWD=${2}
BUILD_CHECK=${3:-"--false"}
PARAM_CHECKS_ONLY=${4:-"--false"}
COMPONENT_TARGET=${5:-"--none"}
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
echo "COMPONENT_TARGET:" $COMPONENT_TARGET
echo "BUILD_TYPE:" $BUILD_TYPE
echo "COMPONENT_ONLY_BUILDS:" $COMPONENT_ONLY_BUILDS
echo "BUILD_CHANNEL:" $BUILD_CHANNEL
echo "BUILD_TARGET:" $BUILD_TARGET
echo "-------------------------------------"

if [ $PARAM_CHECKS_ONLY == "--false" ]; then
  echo "Copying latest build scripts"
  if [ -e $DIRECTORY_PREFIX/scripts/common ]; then
    rm -rf $DIRECTORY_PREFIX/scripts/common
  fi

  mkdir -p $DIRECTORY_PREFIX/scripts/common
  cp -rf common/scripts/*.* $DIRECTORY_PREFIX/scripts/common/
  cp common/scripts/default_user.sh $DIRECTORY_PREFIX/scripts/common/
  cp launch/scripts/run_time_settings.sh $DIRECTORY_PREFIX/scripts/common/

  if [ -e $DIRECTORY_PREFIX/config ]; then
    rm -rf $DIRECTORY_PREFIX/config
  fi

  mkdir -p $DIRECTORY_PREFIX/config
  cp -rf default-config $DIRECTORY_PREFIX/config/
  cp -rf common/config/*.* $DIRECTORY_PREFIX/config/
fi

if [ $BUILD_CHECK == "--true" ]; then
  if [ $COMPONENT_TARGET != "--none" ]  && [ $COMPONENT_TARGET != "--rebuild-all" ] && [ $COMPONENT_TARGET != "--rootfs" ] && [ $COMPONENT_TARGET != "--common-libraries" ] && [ $COMPONENT_TARGET != "--guest" ] && [ $COMPONENT_TARGET != "--host" ] && [ $COMPONENT_TARGET != "--kernel" ]; then
    echo "Invalid COMPONENT_TARGET. Please check build_options.txt file for supported combinations."
    exit 1
  fi

  if [ $COMPONENT_TARGET == "--rootfs" ]; then
    if [ $BUILD_TYPE != "--none" ] && [ $BUILD_TYPE != "--really-clean" ]; then
      echo "Invalid Build Type. Please check build_options.txt file for supported combinations with this component."
      exit 1
    fi
  else
    if [ $BUILD_TYPE != "--clean" ] && [ $BUILD_TYPE != "--incremental" ] && [ $BUILD_TYPE != "--really-clean" ]; then
      echo "Invalid Build Type. Valid Values:--clean, --incremental, --really-clean"
      exit 1
    fi
  fi

  if [ $COMPONENT_ONLY_BUILDS != "--x11" ] && [ $COMPONENT_ONLY_BUILDS != "--wayland" ]  && [ $COMPONENT_ONLY_BUILDS != "--drivers" ] && [ $COMPONENT_ONLY_BUILDS != "--kernel" ] && [ $COMPONENT_ONLY_BUILDS != "--all" ] && [ $COMPONENT_ONLY_BUILDS != "--demos" ]; then
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

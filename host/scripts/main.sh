#! /bin/bash

# run-rootfs-builder.sh [USERNAME PASSWORD CONFIG_FILE MOUNT_POINT]
# Generate debian rootfs image using specified config file and mounted in the
# container at the specified path (should match mountPoint specified in json file)

BUILD_TYPE=$1
COMPONENT_ONLY_BUILDS=$2
BUILD_CHANNEL=$3
BUILD_TARGET=$4

LOCAL_DIRECTORY_PREFIX=/build
LOCAL_BUILD_CHANNEL="--dev"
LOCAL_BUILD_TARGET="--release"
LOCAL_BUILD_TYPE=$BUILD_TYPE
LOG_DIR=/log/host
SCRIPTS_DIR=/scripts/host

source $SCRIPTS_DIR/error_handler_internal.sh $LOG_DIR main_host_err.log --none

echo "main: Recieved Arguments...."
if bash $SCRIPTS_DIR/common_checks_internal.sh $LOCAL_DIRECTORY_PREFIX /build --true --true --none $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET --false; then
  echo “Preparing for build...”
else
  echo “Invalid build options, exit status: $?”
  exit 1
fi
echo "--------------------------"

if [ $BUILD_CHANNEL == "--stable" ]; then
  LOCAL_BUILD_CHANNEL="--stable"
else
  if [ $BUILD_CHANNEL == "--all" ]; then
  LOCAL_BUILD_CHANNEL="--all"
  fi
fi

if [ $BUILD_TARGET == "--debug" ]; then
  LOCAL_BUILD_TARGET="--debug"
else
  if [ $BUILD_TARGET == "--all" ]; then
  LOCAL_BUILD_TARGET="--all"
  fi
fi

echo "Directory Prefix being used:" $LOCAL_DIRECTORY_PREFIX

if [ $LOCAL_BUILD_CHANNEL == "--all" ]; then
  echo "Build Tree: dev, Stable"
  if [ $BUILD_TYPE == "--really-clean" ]; then
    rm -rf/opt/stable
    rm -rf /opt/dev
    LOCAL_BUILD_TYPE="--clean"
  fi
fi

if [ $LOCAL_BUILD_CHANNEL == "--dev" ]; then
  echo "Build Tree: dev"
  if [ $BUILD_TYPE == "--really-clean" ]; then
    rm -rf /opt/dev
    LOCAL_BUILD_TYPE="--clean"
  fi
fi

if [ $LOCAL_BUILD_CHANNEL == "--stable" ]; then
  echo "Build Tree: Stable"
  if [ $BUILD_TYPE == "--really-clean" ]; then
    rm -rf /opt/stable
    LOCAL_BUILD_TYPE="--clean"
  fi
fi

if [ $LOCAL_BUILD_TARGET == "--all" ]; then
  echo "Build Target: Release, Debug"
fi

if [ $LOCAL_BUILD_TARGET == "--release" ]; then
  echo "Build Target: Release"
fi

if [ $LOCAL_BUILD_TARGET == "--debug" ]; then
  echo "Build Tree: Debug"
fi

echo "main: Using Arguments...."
echo "LOCAL_DIRECTORY_PREFIX:" $LOCAL_DIRECTORY_PREFIX
echo "LOCAL_BUILD_CHANNEL:" $LOCAL_BUILD_CHANNEL
echo "LOCAL_BUILD_TARGET:" $LOCAL_BUILD_TARGET
echo "LOCAL_BUILD_TYPE:" $LOCAL_BUILD_TYPE
echo "LOG_DIR:" $LOG_DIR
echo "--------------------------"

build_host() {
if [ $COMPONENT_ONLY_BUILDS == "--vm" ] || [ $COMPONENT_ONLY_BUILDS == "--all" ]; then
  build_target="${1}"
  build_type="${2}"
  channel="${3}"
  
  if [ $LOCAL_BUILD_CHANNEL != $channel ] && [ $LOCAL_BUILD_CHANNEL != "--all" ]; then
    return 0;
  fi

  if [ $LOCAL_BUILD_TARGET != $build_target ] && [ $LOCAL_BUILD_TARGET != "--all" ]; then
  return 0;
  fi
  
  bash $SCRIPTS_DIR/build_host_packages.sh $build_target $build_type $channel
fi
}

# Build all UMD and user space libraries.
#------------------------------------Dev Channel-----------"
echo "Building User Mode Graphics Drivers..."
#Debug
build_host --debug $LOCAL_BUILD_TYPE --dev

# Release Builds.
build_host --release $LOCAL_BUILD_TYPE --dev
#----------------------------Dev Channel ends-----------------

#------------------------------------Stable Channel-----------"
#Debug
build_host --debug $LOCAL_BUILD_TYPE --stable

# Release Builds.
build_host --release $LOCAL_BUILD_TYPE --stable
#----------------------------stable Channel ends-----------------

echo "Done!"

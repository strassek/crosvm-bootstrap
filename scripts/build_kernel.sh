#! /bin/bash

# package-builder.sh
# Builds all needed drivers, cros_vm and other needed packages.


set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

BUILD_TYPE=${1:-"--release"}
CLEAN_BUILD=${2:-"--incremental"}
BUILD_CHANNEL=${3:-"--stable"}
LOCAL_BUILD_TYPE=release
LOCAL_CHANNEL=stable

if /build/output/scripts/common_build_internal.sh $BUILD_TYPE $CLEAN_BUILD $BUILD_CHANNEL --64bit
then
  echo "Starting Build...."
else
  echo "Unable to setup proper build environment. Quitting..."
  exit 1
fi

if [ $BUILD_CHANNEL == "--dev" ]; then
LOCAL_CHANNEL=dev
fi

if [ $BUILD_TYPE == "--debug" ]; then
LOCAL_BUILD_TYPE=debug
fi

# Export environment variables
LOCAL_CURRENT_WLD_PATH=/opt/$LOCAL_CHANNEL/$LOCAL_BUILD_TYPE/x86_64
export C_INCLUDE_PATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
export CPLUS_INCLUDE_PATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
export CPATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
export PATH="$PATH:$LOCAL_CURRENT_WLD_PATH/include/:$LOCAL_CURRENT_WLD_PATH/include/libdrm/:$LOCAL_CURRENT_WLD_PATH/bin"
export PKG_CONFIG_PATH=$LOCAL_CURRENT_WLD_PATH/lib/pkgconfig:$LOCAL_CURRENT_WLD_PATH/share/pkgconfig
export PATH="$PATH:$LOCAL_CURRENT_WLD_PATH/bin"

# Set Working Build directory based on the channel.
WORKING_DIR=/build/$LOCAL_CHANNEL/drivers-

echo "Working Directory:" $WORKING_DIR

export PKG_CONFIG_PATH=$LOCAL_CURRENT_WLD_PATH/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH

env
echo "---------------------------------"

cd /build

cd $WORKING_DIR/kernel
if [[ ($CLEAN_BUILD == "--clean" && -d $KERNEL_OUTPUT_DIR) ]]; then
  make -j0  clean || true
fi
  
make -j0  x86_64_defconfig
make -j0
if [ -f vmlinux ]; then
  if [ -e /build/output ]; then
    mv vmlinux /host/$LOCAL_CHANNEL/
  fi
fi

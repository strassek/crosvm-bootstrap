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

BASE_DIR=${1}
COMPONENT_TARGET=${2:-"--none"}
BUILD_TYPE=${3:-"--clean"} # Possible values: --clean, --incremental --really-clean
COMPONENT_ONLY_BUILDS=${4:-"--all"}
BUILD_CHANNEL=${5:-"--stable"} # Possible values: --dev, --stable, --all
BUILD_TARGET=${6:-"--release"} # Possible values: --release, --debug, --all

if [ $COMPONENT_TARGET == "--rootfs" ] || [ $COMPONENT_TARGET == "--rebuild-all" ] ; then
  # Create Base image. This will be used for Host and cloning source code.
  if bash common/common_internal.sh $BASE_DIR $COMPONENT_TARGET $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET --true; then
    echo “Built rootfs with default usersetup.”
  else
    echo “Failed to built rootfs with default usersetup, exit status: $?”
    exit 1
  fi
fi

if [ $COMPONENT_TARGET == "--common-libraries" ] || [ $COMPONENT_TARGET == "--rebuild-all" ] ; then
  if bash common/common_components_internal.sh $BASE_DIR $COMPONENT_TARGET $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET --false; then
    echo “Built all common libraries to be used by host and guest”
  else
    echo “Failed to build common libraries to be used by host and guest. exit status: $?”
    exit 1
  fi
fi

if [ $COMPONENT_TARGET == "--host" ] || [ $COMPONENT_TARGET == "--rebuild-all" ] ; then
  # Create Base image. This will be used for Host and cloning source code.
  if bash host/build_host_internal.sh $BASE_DIR $COMPONENT_TARGET $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET; then
    echo “Built host rootfs.”
  else
    echo “Failed to build host rootfs. exit status: $?”
    exit 1
  fi
fi

if [ $COMPONENT_TARGET == "--guest" ] || [ $COMPONENT_TARGET == "--rebuild-all" ] ; then
  # Create Base image. This will be used for Host and cloning source code.
  if bash guest/build_guest_internal.sh $BASE_DIR $COMPONENT_TARGET $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET; then
    echo “Built guest rootfs.”
  else
    echo “Failed to build guest rootfs. exit status: $?”
    exit 1
  fi
fi

if [ $COMPONENT_TARGET == "--kernel" ] || [ $COMPONENT_TARGET == "--rebuild-all" ] ; then
  echo "Preparing to build Kernel...."
  LOCAL_BUILD_CHANNEL=stable
  if [ $BUILD_CHANNEL == "--dev" ]; then
    LOCAL_BUILD_CHANNEL=dev
  fi

  cd $BASE_DIR/source/$LOCAL_BUILD_CHANNEL/drivers/kernel/
  if [ $BUILD_TYPE == "--clean" ]; then
    make clean || true
  fi

  make x86_64_defconfig
  make
  if [ -f vmlinux ]; then
    mkdir -p $BASE_DIR/build/images/
    if [ -e $BASE_DIR/build/images/vmlinux ]; then
      rm $BASE_DIR/build/images/vmlinux
    fi

    mv vmlinux $BASE_DIR/build/images/
  fi
fi


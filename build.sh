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
INITIAL_BUILD_SETUP=${2:-"--none"}
GUEST_ONLY=${3:-"--false"}
HOST_ONLY=${4:-"--false"}
KERNEL_ONLY=${5:-"--false"}
BUILD_TYPE=${6:-"--clean"} # Possible values: --clean, --incremental --really-clean
COMPONENT_ONLY_BUILDS=${7:-"--all"}
BUILD_CHANNEL=${8:-"--stable"} # Possible values: --dev, --stable, --all
BUILD_TARGET=${9:-"--release"} # Possible values: --release, --debug, --all

cleanup_docker_image() {
  if [[ "$(docker images -q intel-temp:latest 2> /dev/null)" != "" ]]; then
    docker rmi -f intel-temp:latest
  fi
}

if [ $GUEST_ONLY != "--true" ] && [ $KERNEL_ONLY != "--true" ]; then
  # Create Base image. This will be used for Host and cloning source code.
  if bash host/build_vm_internal.sh $BASE_DIR $INITIAL_BUILD_SETUP $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET --true; then
    echo “Cloning Source...”
  else
    echo “Failed to create base image, exit status: $? Please check Docker is setup correctly.”
    exit 1
  fi
fi

if [ $GUEST_ONLY != "--true" ] && [ $KERNEL_ONLY != "--true" ]; then
  # Create Host image.
  if [ $INITIAL_BUILD_SETUP == "--rebuild-all" ]; then
    INITIAL_BUILD_SETUP="--rebuild-drivers"
  fi

  if bash host/build_vm_internal.sh $BASE_DIR $INITIAL_BUILD_SETUP $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET --false; then
    echo “Cloning Source...”
  else
    echo “Failed to create host image, exit status: $?”
    cleanup_docker_image
    exit 1
  fi
fi

if [ $HOST_ONLY == "--true" ]; then
  exit 0
fi

if [ $KERNEL_ONLY != "--true" ]; then
  # Create Base image. This will be used for guest.
  echo "Preparing to build Guest image...."
  if bash guest/build_guest_internal.sh $BASE_DIR $INITIAL_BUILD_SETUP $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET --false; then
    echo “Cloning Source...”
  else
    echo “Failed to create guest image, exit status: $?”
    cleanup_docker_image
    exit 1
  fi

  if [ $GUEST_ONLY == "--true" ]; then
    exit 0
  fi
fi

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


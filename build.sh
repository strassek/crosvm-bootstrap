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

COMPONENT_TARGET=${1:-"--none"}
BUILD_TYPE=${2:-"--clean"} # Possible values: --clean, --incremental --really-clean
COMPONENT_ONLY_BUILDS=${3:-"--all"}
BUILD_CHANNEL=${4:-"--stable"} # Possible values: --dev, --stable, --all
BUILD_TARGET=${5:-"--release"} # Possible values: --release, --debug, --all

BASE_DIR=$PWD
LOCAL_REGENERATE=$COMPONENT_TARGET

# Ensure build directory is setup correctly.
if [ $COMPONENT_TARGET == "--rebuild-all" ] ; then
  rm -rf build/
fi

if [ ! -e $BASE_DIR/build ]; then
  mkdir $BASE_DIR/build
fi

if [ ! -e $BASE_DIR/build/rootfs ]; then
  cp -rf $BASE_DIR/rootfs build/rootfs
fi

if [ -e $BASE_DIR/build/config ]; then
  rm -rf $BASE_DIR/build/config
fi

if [ ! -e $BASE_DIR/build/containers ]; then
  mkdir $BASE_DIR/build/containers
fi

mkdir -p $BASE_DIR/build/config
cp -rf default-config $BASE_DIR/build/config

if [ -e $BASE_DIR/build/scripts/common ]; then
  rm -rf $BASE_DIR/build/scripts/common
fi

mkdir -p $BASE_DIR/build/scripts/common
cp -rf $BASE_DIR/common/scripts/*.* $BASE_DIR/build/scripts/common

LOCAL_BUILD_HOST="false"
if [[ "$COMPONENT_TARGET" == "--host" ]] && [[ "$BUILD_TYPE" == "--really-clean" ]]; then
  LOCAL_BUILD_HOST="true"
fi

if [[ "$COMPONENT_TARGET" == "--host" ]] || [[ "$COMPONENT_TARGET" == "--rebuild-all" ]] || [[ "$LOCAL_BUILD_HOST" == "true" ]]; then
  if [ -e $BASE_DIR/build/scripts/host ]; then
    rm -rf $BASE_DIR/build/scripts/host
  fi
  
  if [[ "$(docker images -q intel_host 2> /dev/null)" != "" ]]; then
	docker rmi -f intel_host:latest
  fi

  mkdir -p $BASE_DIR/build/scripts/host
  cp -rf $BASE_DIR/host/scripts/*.* $BASE_DIR/build/scripts/host

  if [ $COMPONENT_TARGET == "--rebuild-all" ] || [[ "$BUILD_TYPE" == "--really-clean" ]]; then
    # Create Base image. This will be used for Host and cloning source code.
    if bash rootfs/create_rootfs.sh $BASE_DIR 'host' '--really-clean'; then
      echo “Built rootfs with default usersetup.”
    else
      echo “Failed to built rootfs with default usersetup, exit status: $?”
      exit 1
    fi
  fi

  if bash common/common_components_internal.sh $BASE_DIR 'common-libraries' $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET; then
    echo “Built all common libraries to be used by host and guest”
    LOCAL_REGENERATE='--rebuild-all'
  else
    echo “Failed to build common libraries to be used by host and guest. exit status: $?”
    exit 1
  fi

  # Create Base image. This will be used for Host and cloning source code.
  if bash host/build_host_internal.sh $BASE_DIR $LOCAL_REGENERATE $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET; then
    echo “Built host rootfs.”
  else
    echo “Failed to build host rootfs. exit status: $?”
    exit 1
  fi
fi

LOCAL_REGENERATE=$COMPONENT_TARGET
cd $BASE_DIR/
UPDATE_CONTAINER='--false'

LOCAL_BUILD_GAME_FAST="false"
if [[ "$COMPONENT_TARGET" == "--game-fast" ]] && [[ "$BUILD_TYPE" == "--really-clean" ]]; then
  LOCAL_BUILD_GAME_FAST="true"
fi

if [[ "$COMPONENT_TARGET" == "--game-fast" ]] || [[ "$COMPONENT_TARGET" == "--rebuild-all" ]] || [[ "$LOCAL_REGENERATE" == "--rebuild-all" ]] || [[ "$LOCAL_BUILD_GAME_FAST" == "true" ]]; then
  if [ -e $BASE_DIR/build/scripts/game_fast ]; then
    rm -rf $BASE_DIR/build/scripts/game_fast
  fi

  LOCAL_BUILD_TYPE=$BUILD_TYPE

  mkdir -p $BASE_DIR/build/scripts/game-fast
  cp -rf $BASE_DIR/game_fast/scripts/*.* $BASE_DIR/build/scripts/game-fast

  if [[ "$COMPONENT_TARGET" == "--rebuild-all" ]] || [[ "$BUILD_TYPE" == "--really-clean" ]] || [[ "$LOCAL_REGENERATE" == "--rebuild-all" ]] ||  [[ ! -e  "$BASE_DIR/build/containers/rootfs_game_fast.ext4" ]]; then
    LOCAL_REGENERATE="--rebuild-all"
    LOCAL_BUILD_TYPE="--clean"
    # Create Base image. This will be used for Host and cloning source code.
    if bash rootfs/create_rootfs.sh $BASE_DIR 'game-fast' '--really-clean'; then
      echo “Built rootfs with default usersetup.”
    else
      echo “Failed to built rootfs with default usersetup, exit status: $?”
      exit 1
    fi
  fi
fi

LOCAL_BUILD_GUEST="false"
if [[ "$COMPONENT_TARGET" == "--guest" ]] && [[ "$BUILD_TYPE" == "--really-clean" ]]; then
  LOCAL_BUILD_GUEST="true"
fi

if [[ "$COMPONENT_TARGET" == "--guest" ]]; then
  UPDATE_CONTAINER='--true'
fi

if [[ "$UPDATE_CONTAINER" == "--true" ]] || [[ "$COMPONENT_TARGET" == "--guest" ]] || [[ "$COMPONENT_TARGET" == "--rebuild-all" ]] || [[ "$LOCAL_REGENERATE" == "--rebuild-all" ]] || [[ "$LOCAL_BUILD_GUEST" == "true" ]]; then
  if [ -e $BASE_DIR/build/scripts/guest ]; then
    rm -rf $BASE_DIR/build/scripts/guest
  fi

  mkdir -p $BASE_DIR/build/scripts/guest
  cp -rf $BASE_DIR/guest/scripts/*.* $BASE_DIR/build/scripts/guest/
  RECREATE_GUEST_ROOTFS=0
  
  if [[ "$BUILD_TYPE" == "--really-clean" ]] && [[ "$COMPONENT_TARGET" == "--guest" ]]; then
    RECREATE_GUEST_ROOTFS=1
  fi
  
  LOCAL_BUILD_TYPE=$BUILD_TYPE

  if [[ "$COMPONENT_TARGET" == "--rebuild-all" ]] || [[ "$LOCAL_REGENERATE" == "--rebuild-all" ]] || [[ $RECREATE_GUEST_ROOTFS == "1" ]] || [[ ! -e $BASE_DIR/build/images/rootfs_guest.ext4 ]]; then
    if bash rootfs/create_rootfs.sh $BASE_DIR 'guest' '--really-clean' '10000'; then
      LOCAL_BUILD_TYPE="--clean"
      echo “Built guest with default usersetup.”
    else
      echo “Failed to built rootfs with default usersetup, exit status: $?”
      exit 1
    fi
  fi
  
  if bash common/common_components_internal.sh $BASE_DIR 'guest' $LOCAL_BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET; then
    echo “Built all common libraries to be used by Guest.”
  else
    echo “Failed to build common libraries to be used by Guest. exit status: $?”
    exit 1
  fi  
fi

if [[ "$COMPONENT_TARGET" == "--kernel" ]] || [[ "$COMPONENT_TARGET" == "--rebuild-all" ]] ; then
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

if [ -e $BASE_DIR/build/launch ]; then
  sudo rm -rf $BASE_DIR/build/launch
fi

if [[ -e "$BASE_DIR/build/containers/rootfs_host.ext4" ]] && [[ -e "$BASE_DIR/build/containers/rootfs_game_fast.ext4" ]] && [[ -e "$BASE_DIR/build/images/rootfs_guest.ext4" ]] && [[ -e "$BASE_DIR/build/images/vmlinux" ]]; then
	mkdir -p $BASE_DIR/build/launch
	mkdir -p $BASE_DIR/build/launch/images
	mkdir -p $BASE_DIR/build/launch/docker/
	mkdir -p $BASE_DIR/build/launch/shared/
	mkdir -p $BASE_DIR/build/launch/shared/containers
	mkdir -p $BASE_DIR/build/launch/shared/guest
	mkdir -p $BASE_DIR/build/launch/shared/guest/igt
	cd $BASE_DIR/build/launch
	cp $BASE_DIR/launcher.sh .
	cp -rpvf $BASE_DIR/launch .
	cp $BASE_DIR/launch/docker/start.dockerfile $BASE_DIR/build/launch/docker/Dockerfile-start
	cp $BASE_DIR/launch/docker/stop.dockerfile $BASE_DIR/build/launch/docker/Dockerfile-stop
	cp -rpvf $BASE_DIR/tools/*.sh $BASE_DIR/build/launch/launch/scripts/
	cp $BASE_DIR/build/containers/rootfs_host.ext4 images/
	cp $BASE_DIR/build/containers/rootfs_game_fast.ext4 $BASE_DIR/build/launch/shared/containers/
	cp $BASE_DIR/build/images/rootfs_guest.ext4 images/
	cp $BASE_DIR/build/images/vmlinux images/
fi

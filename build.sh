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

INITIAL_BUILD_SETUP=${1:-"--none"}
BUILD_TYPE=${2:-"--clean"} # Possible values: --clean, --incremental --really-clean
COMPONENT_ONLY_BUILDS=${3:-"--all"}
TARGET_ARCH=${4:-"--all"}
SYNC_SOURCE=${5:-"--false"} # Possible values: --true, --false
BUILD_CHANNEL=${6:-"--stable"} # Possible values: --dev, --stable, --all
BUILD_TARGET=${7:-"--release"} # Possible values: --release, --debug, --all
UPDATE_SYSTEM=${8:-"--false"} # Possible values: --true, --false
MOUNT_POINT=${9:-"mount"}

LOCAL_PWD=$PWD/build
SOURCE_PWD=$PWD/source
LOCAL_BUILD_TYPE=$BUILD_TYPE
LOCAL_COMPONENT_ONLY_BUILDS=$COMPONENT_ONLY_BUILDS
LOCAL_INITIAL_BUILD_SETUP=$INITIAL_BUILD_SETUP
LOCAL_SYNC_SOURCE=$SYNC_SOURCE
LOG_BUILD_DIR=""

if [ ! -e $LOCAL_PWD ]; then
  mkdir -p $LOCAL_PWD/output/scripts
  mkdir -p $LOCAL_PWD/config
  mkdir -p $PWD/source
  cp -rf scripts/*.* build/output/scripts/
  cp default-config/*.json build/config
  cp -rf default-config/guest build/config/guest
else
  if bash scripts/common_checks_internal.sh --docker; then
    echo “Preparing docker...”
  else
    echo “Failed to find needed dependencies, exit status: $?”
    exit 1
  fi
fi

if [ $LOCAL_INITIAL_BUILD_SETUP == "--rebuild-rootfs" ]; then
# Remove any old rootfs images
echo "Checking for existing rootfs images."
  if [ -e $LOCAL_PWD/output/rootfs.ext4 ]; then
    echo "Destroyed rootfs image."
    rm $LOCAL_PWD/output/rootfs.ext4;
  else
    echo "No pre-existing rootfs image exist."
  fi

  if [ -e $LOCAL_PWD/output/dev ]; then
    rm -rf $LOCAL_PWD/output/dev;
  fi

  if [ -e $LOCAL_PWD/output/stable ]; then
    rm -rf $LOCAL_PWD/output/stable;
  fi
fi

if [ $LOCAL_INITIAL_BUILD_SETUP == "--recreate-source-image-only" ]; then
# Remove any old rootfs images
  if [ -e $SOURCE_PWD/source/source.ext4 ]; then
    rm $SOURCE_PWD/source/source.ext4;
  fi
fi

rm -rf build/docker/
mkdir -p build/docker/
cp dockerfiles/builder.dockerfile build/docker/Dockerfile
cd $LOCAL_PWD/docker/

SHA=`git rev-parse --short HEAD`
TAG=`git describe --always`
if [ -z $? ]; then
    echo "$TAG" > VERSION
else
    echo "COMMIT-$SHA" > VERSION
fi

if [ $BUILD_TYPE == "--clean" ]; then
  docker image rm package-builder -f
fi

echo “building docker...”
docker build -t package-builder:latest .
LOG_BUILD_DIR=`date "+%y%m%d-%H%M"`
mkdir -p $LOCAL_PWD/output/$LOG_BUILD_DIR

if [ ! -e $LOCAL_PWD/output/rootfs.ext4 ]; then
  docker run -it --privileged -v $LOCAL_PWD/output:/app/output -v $LOCAL_PWD/config:/app/config package-builder:latest --docker --create-rootfs-image-only $LOCAL_BUILD_TYPE $LOCAL_COMPONENT_ONLY_BUILDS $TARGET_ARCH $LOCAL_SYNC_SOURCE $BUILD_CHANNEL $BUILD_TARGET $UPDATE_SYSTEM $LOG_BUILD_DIR $MOUNT_POINT > >(tee -a $LOCAL_PWD/output/$LOG_BUILD_DIR/rootfs.log) 2> >(tee -a $LOCAL_PWD/output/$LOGDIR/rootfs.err) >&2
  LOCAL_INITIAL_BUILD_SETUP="--bootstrap"
fi

if [ $LOCAL_INITIAL_BUILD_SETUP == "--bootstrap" ]; then
echo "Bootstrap Debian...."
docker run -it --privileged -v $LOCAL_PWD/output:/app/output -v $LOCAL_PWD/config:/app/config package-builder:latest --docker $LOCAL_INITIAL_BUILD_SETUP $LOCAL_BUILD_TYPE $LOCAL_COMPONENT_ONLY_BUILDS $TARGET_ARCH $LOCAL_SYNC_SOURCE $BUILD_CHANNEL $BUILD_TARGET $UPDATE_SYSTEM $LOG_BUILD_DIR $MOUNT_POINT > >(tee -a $LOCAL_PWD/output/$LOG_BUILD_DIR/bootstrap.log) 2> >(tee -a $LOCAL_PWD/output/$LOGDIR/bootstrap.err) >&2
LOCAL_INITIAL_BUILD_SETUP="--setup-initial-environment"
fi

if [ $LOCAL_INITIAL_BUILD_SETUP == "--setup-initial-environment" ]; then
echo "Setting up initial environment."
docker run -it --privileged -v $LOCAL_PWD/output:/app/output -v $LOCAL_PWD/config:/app/config package-builder:latest --docker $LOCAL_INITIAL_BUILD_SETUP $LOCAL_BUILD_TYPE $LOCAL_COMPONENT_ONLY_BUILDS $TARGET_ARCH $LOCAL_SYNC_SOURCE $BUILD_CHANNEL $BUILD_TARGET $UPDATE_SYSTEM $LOG_BUILD_DIR $MOUNT_POINT > >(tee -a $LOCAL_PWD/output/$LOG_BUILD_DIR/initial_env_setup.log) 2> >(tee -a $LOCAL_PWD/output/$LOGDIR/initial_env_setup.err) >&2
LOCAL_BUILD_TYPE="--really-clean"
LOCAL_SYNC_SOURCE="--true"
fi

if [ ! -e $SOURCE_PWD/source/source.ext4 ]; then
docker run -it --privileged -v $SOURCE_PWD/source:/app/source -v $LOCAL_PWD/output:/app/output -v $LOCAL_PWD/config:/app/config package-builder:latest --docker --create-source-image-only $LOCAL_BUILD_TYPE $LOCAL_COMPONENT_ONLY_BUILDS $TARGET_ARCH $LOCAL_SYNC_SOURCE $BUILD_CHANNEL $BUILD_TARGET $UPDATE_SYSTEM $LOG_BUILD_DIR $MOUNT_POINT > >(tee -a $LOCAL_PWD/output/$LOG_BUILD_DIR/source_image.log) 2> >(tee -a $LOCAL_PWD/output/$LOGDIR/source_image.err) >&2
LOCAL_BUILD_TYPE="--really-clean"
LOCAL_SYNC_SOURCE="--false"
fi

LOCAL_INITIAL_BUILD_SETUP="--none"

docker run -it --privileged -v $SOURCE_PWD/source:/app/source -v $LOCAL_PWD/output:/app/output -v $LOCAL_PWD/config:/app/config package-builder:latest --docker $LOCAL_INITIAL_BUILD_SETUP $LOCAL_BUILD_TYPE $LOCAL_COMPONENT_ONLY_BUILDS $TARGET_ARCH $LOCAL_SYNC_SOURCE $BUILD_CHANNEL $BUILD_TARGET $UPDATE_SYSTEM $LOG_BUILD_DIR $MOUNT_POINT

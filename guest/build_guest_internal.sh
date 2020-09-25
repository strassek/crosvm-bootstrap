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

SOURCE_PWD=${1}
INITIAL_BUILD_SETUP=${2:-"--none"}
BUILD_TYPE=${3:-"--clean"} # Possible values: --clean, --incremental --really-clean
COMPONENT_ONLY_BUILDS=${4:-"--all"}
BUILD_CHANNEL=${5:-"--stable"} # Possible values: --dev, --stable, --all
BUILD_TARGET=${6:-"--release"} # Possible values: --release, --debug, --all
CREATE_BASE_IMAGE_ONLY=${7:-"--false"} # Possible values: --false, --true

LOCAL_PWD=$PWD/build
SOURCE_PWD=$SOURCE_PWD
LOCAL_BUILD_TYPE=$BUILD_TYPE
LOCAL_COMPONENT_ONLY_BUILDS=$COMPONENT_ONLY_BUILDS
LOCAL_INITIAL_BUILD_SETUP=$INITIAL_BUILD_SETUP
 
if bash guest/scripts/common_checks_internal.sh $LOCAL_PWD $SOURCE_PWD/source --true --false $INITIAL_BUILD_SETUP $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET  $CREATE_BASE_IMAGE_ONLY; then
  echo “Preparing docker...”
else
  echo “Failed to find needed dependencies, exit status: $?”
  exit 1
fi

destroy_docker_images() {
if [ $INITIAL_BUILD_SETUP == "--none" ]; then
  return;
fi

if [ $INITIAL_BUILD_SETUP == "--rebuild-all" ]; then
  if [[ "$(docker images -q intel-base-guest:latest 2> /dev/null)" != "" ]]; then
    docker rmi -f intel-base-guest:latest
  fi
fi

if [ $INITIAL_BUILD_SETUP == "--rebuild-all" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-x11" ]; then
  if [[ "$(docker images -q intel-x11-guest:latest 2> /dev/null)" != "" ]]; then
    docker rmi -f intel-x11-guest:latest
  fi
fi

if [ $INITIAL_BUILD_SETUP == "--rebuild-all" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-x11" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-wayland" ]; then
  if [[ "$(docker images -q intel-wayland-guest:latest 2> /dev/null)" != "" ]]; then
    docker rmi -f intel-wayland-guest:latest
  fi
fi

if [ $INITIAL_BUILD_SETUP == "--rebuild-all" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-x11" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-wayland" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-drivers" ]; then
  if [[ "$(docker images -q intel-drivers-guest:latest 2> /dev/null)" != "" ]]; then
    docker rmi -f intel-drivers-guest:latest
  fi
fi

if [ $INITIAL_BUILD_SETUP == "--rebuild-all" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-x11" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-wayland" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-drivers" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-demos" ]; then
  if [[ "$(docker images -q intel-demos-guest:latest 2> /dev/null)" != "" ]]; then
    docker rmi -f intel-demos-guest:latest
  fi
fi

if [ $INITIAL_BUILD_SETUP == "--rebuild-all" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-drivers" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-vm" ]; then
  if [[ "$(docker images -q intel-guest:latest 2> /dev/null)" != "" ]]; then
    docker rmi -f intel-vm-guest:latest
  fi
fi
}

destroy_docker_images

SHA=`git rev-parse --short HEAD`
TAG=`git describe --always`
if [ -z $? ]; then
    echo "$TAG" > VERSION
else
    echo "COMMIT-$SHA" > VERSION
fi

# Handle base builds
echo "Checking for base guest image..."
if [[ "$(docker images -q intel-base-guest:latest 2> /dev/null)" == "" ]]; then
  cd $LOCAL_PWD/docker/guest/
  docker build -t intel-base-guest:latest -f Dockerfile.base-guest .
  LOCAL_COMPONENT_ONLY_BUILDS="--all"
fi

if [ $CREATE_BASE_IMAGE_ONLY == "--true" ]; then
  exit 0;
fi

echo "Building components."

building_component() {
component="${1}"
docker_image="${2}"
echo "running docker" $docker_image
if docker run -it --privileged --mount type=bind,source=$SOURCE_PWD/source,target=/build --mount type=bind,source=$LOCAL_PWD/scripts,target=/scripts intel-temp:latest $LOCAL_BUILD_TYPE $component $BUILD_CHANNEL $BUILD_TARGET; then
  echo "committing------------"
  export CONTAINER_ID=`docker ps -lq`
  docker commit $CONTAINER_ID $docker_image
  docker rmi -f intel-temp:latest
else
  docker rmi -f intel-temp:latest
  exit 1
fi
}

if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--x11" ]; then
  cd $LOCAL_PWD/docker/guest
  docker build -t intel-temp:latest -f Dockerfile.x11-guest .
  building_component "--x11" "intel-x11-guest"
fi

if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--wayland" ]; then
  if [[ "$(docker images -q intel-x11-guest:latest 2> /dev/null)" == "" ]]; then
    echo "wayland is not built. Please build x11 first. i.e. COMPONENT_ONLY_BUILDS=--all or COMPONENT_ONLY_BUILDS=--wayland"
    exit 1
  fi
  
  cd $LOCAL_PWD/docker/guest
  docker build -t intel-temp:latest -f Dockerfile.wayland-guest .
  building_component "--wayland" "intel-wayland-guest"
fi

if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--drivers" ]; then
  if [[ "$(docker images -q intel-wayland-guest:latest 2> /dev/null)" == "" ]]; then
    echo "wayland is not built. Please build wayland first. i.e. COMPONENT_ONLY_BUILDS=--all or COMPONENT_ONLY_BUILDS=--wayland"
    exit 1
  fi
  
  cd $LOCAL_PWD/docker/guest
  docker build -t intel-temp:latest -f Dockerfile.drivers-guest .
  building_component "--drivers" "intel-drivers-guest:latest"
fi

if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--guest" ]; then
  if [[ "$(docker images -q intel-drivers-guest:latest 2> /dev/null)" == "" ]]; then
    echo "wayland is not built. Please build drivers first. i.e. COMPONENT_ONLY_BUILDS=--all or COMPONENT_ONLY_BUILDS=--drivers"
    exit 1
  fi

  cd $LOCAL_PWD/docker/guest
  docker build -t intel-temp:latest -f Dockerfile-guest .
  building_component "--guest" "intel-guest:latest"
fi
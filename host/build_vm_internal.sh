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
 
if bash host/scripts/common_checks_internal.sh $LOCAL_PWD $SOURCE_PWD/source --true --false $INITIAL_BUILD_SETUP $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET  $CREATE_BASE_IMAGE_ONLY; then
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
  if [[ "$(docker images -q intel-base:latest 2> /dev/null)" != "" ]]; then
    docker rmi -f intel-base:latest
  fi
fi

if [ $INITIAL_BUILD_SETUP == "--rebuild-all" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-x11" ]; then
  if [[ "$(docker images -q intel-x11:latest 2> /dev/null)" != "" ]]; then
    docker rmi -f intel-x11:latest
  fi
fi

if [ $INITIAL_BUILD_SETUP == "--rebuild-all" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-x11" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-wayland" ]; then
  if [[ "$(docker images -q intel-wayland:latest 2> /dev/null)" != "" ]]; then
    docker rmi intel-wayland:latest -f
  fi
fi

if [ $INITIAL_BUILD_SETUP == "--rebuild-all" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-x11" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-wayland" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-drivers" ]; then
  if [[ "$(docker images -q intel-drivers:latest 2> /dev/null)" != "" ]]; then
    docker rmi intel-drivers:latest -f
  fi
fi

if [ $INITIAL_BUILD_SETUP == "--rebuild-all" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-x11" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-wayland" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-drivers" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-demos" ]; then
  if [[ "$(docker images -q intel-demos:latest 2> /dev/null)" != "" ]]; then
    docker rmi intel-demos:latest -f
  fi
fi

if [ $INITIAL_BUILD_SETUP == "--rebuild-all" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-drivers" ] || [ $INITIAL_BUILD_SETUP == "--rebuild-vm" ]; then
  if [[ "$(docker images -q intel-vm:latest 2> /dev/null)" != "" ]]; then
    docker rmi intel-vm:latest -f
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
if [[ "$(docker images -q intel-base:latest 2> /dev/null)" == "" ]]; then
  cd $LOCAL_PWD/docker/host/
  docker build -t intel-base:latest -f Dockerfile.base .
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
  if [ $docker_image == "--vm" ];
    echo "Generating rootfs image..."
    mkdir -p $LOCAL_PWD/images
    cd $LOCAL_PWD/images
    docker export -o rootfs.tar $CONTAINER_ID
    if [ -e rootfs.ext4 ]; then
      rm rootfs.ext4
    fi
    dd if=/dev/zero of=rootfs.ext4 bs=3000 count=1M
    mkfs.ext4 rootfs.ext4
    mkdir -p rootfs_dir/
    mount rootfs.ext4 rootfs_dir/
    tar -xvf rootfs.tar -C rootfs_dir/
    umount rootfs
    rm rootfs_dir
  fi
  docker rmi -f intel-temp:latest
else
  docker rmi -f intel-temp:latest
  exit 1
fi
}

if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--x11" ]; then
  cd $LOCAL_PWD/docker/host
  docker build -t intel-temp:latest -f Dockerfile.x11 .
  building_component "--x11" "intel-x11"
fi

if [[ "$(docker images -q intel-x11:latest 2> /dev/null)" == "" ]]; then
  echo "x11 is not built. Please build x11 first. i.e. COMPONENT_ONLY_BUILDS=--all or COMPONENT_ONLY_BUILDS=--x11"
  exit 1
fi

if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--wayland" ]; then
  cd $LOCAL_PWD/docker/host
  docker build -t intel-temp:latest -f Dockerfile.wayland .
  building_component "--wayland" "intel-wayland"
fi

if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--drivers" ]; then
  if [[ "$(docker images -q intel-wayland:latest 2> /dev/null)" == "" ]]; then
    echo "wayland is not built. Please build wayland first. i.e. COMPONENT_ONLY_BUILDS=--all or COMPONENT_ONLY_BUILDS=--wayland"
    exit 1
  fi
  
  cd $LOCAL_PWD/docker/host
  docker build -t intel-temp:latest -f Dockerfile.drivers .
  building_component "--drivers" "intel-drivers:latest"
fi

if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--demos" ]; then
  if [[ "$(docker images -q intel-drivers:latest 2> /dev/null)" == "" ]]; then
    echo "User Mode drivers are not built. Please build drivers first. i.e. COMPONENT_ONLY_BUILDS=--all or COMPONENT_ONLY_BUILDS=--drivers"
    exit 1
  fi
  
  cd $LOCAL_PWD/docker/host
  docker build -t intel-temp:latest -f Dockerfile.demos .
  building_component "--demos" "intel-demos:latest"
fi

if [ $LOCAL_COMPONENT_ONLY_BUILDS == "--all" ] || [ $LOCAL_COMPONENT_ONLY_BUILDS == "--vm" ]; then
  if [[ "$(docker images -q intel-demos:latest 2> /dev/null)" == "" ]]; then
    echo "User Mode drivers are not built. Please build drivers first. i.e. COMPONENT_ONLY_BUILDS=--all or COMPONENT_ONLY_BUILDS=--demos"
    exit 1
  fi
  
  cd $LOCAL_PWD/docker/host
  docker build -t intel-temp:latest -f Dockerfile.demos .
  building_component "--vm" "intel-vm:latest"
fi

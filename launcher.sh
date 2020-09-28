#! /bin/bash

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

set -ex

BASE_DIRECTORY=${1} # Expected Directory Structure <basefolder>/rootfs.ext4, vmlinux, crosvm
XDG_RUNTIME_DIR=${2}
WAYLAND_DISPLAY=${3}
DISPLAY=${4}
CHANNEL=${5:-"--stable"}
TARGET=${6:-"--release"}
ACTION=${7:-"--run"}

LOCAL_KERNEL_CMD_OPTIONS=""
LOCAL_BUILD_TARGET=release
LOCAL_CHANNEL=stable
pwd="${PWD}"

if [ $TARGET == "--release" ]; then
  LOCAL_KERNEL_CMD_OPTIONS="intel_iommu=on"
else
  LOCAL_KERNEL_CMD_OPTIONS="intel_iommu=on drm.debug=255 debug loglevel=8 initcall_debug"
  LOCAL_BUILD_TARGET=debug
fi

if [ $LOCAL_CHANNEL == "--dev" ]; then
  LOCAL_CHANNEL=dev
fi

if [ -e $BASE_DIRECTORY/docker/exec/ ]; then
  rm -rf $BASE_DIRECTORY/docker/exec/
fi

mkdir -p $BASE_DIRECTORY/docker/exec/

if [ -e $BASE_DIRECTORY/scripts/exec/ ]; then
  rm -rf $BASE_DIRECTORY/scripts/exec/
fi

cp launch/docker/start.dockerfile $BASE_DIRECTORY/docker/exec/Dockerfile-start
cp launch/docker/stop.dockerfile $BASE_DIRECTORY/docker/exec/Dockerfile-stop

if [ -e $BASE_DIRECTORY/scripts/exec/ ]; then
  rm -rf $BASE_DIRECTORY/scripts/exec/
fi

mkdir -p $BASE_DIRECTORY/scripts/exec/
cp launch/scripts/*.sh $BASE_DIRECTORY/scripts/exec/

if [ $ACTION == "--run" ]; then

if [[ "$(docker images -q intel_host:latest 2> /dev/null)" != "" ]]; then
  echo “Preparing to launch crosvm...”
else
  echo “Failed to launch crosvm..., exit status: $?”
  exit 1
fi

if [[ "$(docker images -q intel-vm-launch 2> /dev/null)" != "" ]]; then
  docker rmi -f intel-vm-launch:latest
fi


cd $BASE_DIRECTORY/docker/exec/
docker build -t intel-vm-launch:latest -f Dockerfile-start .
exec docker run -it --rm --privileged \
    --ipc=host \
    -e DISPLAY=$DISPLAY -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
    -v /dev/log:/dev/log \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v /proc:/proc -v /sys:/sys \
    -e container=docker \
    --mount type=bind,source=$BASE_DIRECTORY/images,target=/images \
    --mount type=bind,source=$BASE_DIRECTORY/scripts,target=/scripts \
    intel-vm-launch:latest \
    $LOCAL_CHANNEL $LOCAL_BUILD_TARGET $LOCAL_KERNEL_CMD_OPTIONS run
    
docker rmi -f intel-vm-launch:latest
else
if [ $ACTION == "--stop" ]; then
  if [[ "$(docker images -q intel-vm-stop 2> /dev/null)" != "" ]]; then
    docker rmi -f intel-vm-stop:latest
  fi

  cd $BASE_DIRECTORY/docker/exec/
  docker build -t intel-vm-stop:latest -f Dockerfile-stop .
  exec docker run -it --cap-add net_admin \
      --ipc=host \
      -e DISPLAY=$DISPLAY -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
      -v /dev/log:/dev/log \
      -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
      -v /proc:/proc -v /sys:/sys \
      --mount type=bind,source=$BASE_DIRECTORY/images,target=/images \
      --mount type=bind,source=$BASE_DIRECTORY/scripts,target=/scripts \
      intel-vm-stop:latest \
      $LOCAL_CHANNEL $LOCAL_BUILD_TARGET $LOCAL_KERNEL_CMD_OPTIONS stop
    
  docker rmi -f intel-vm-stop:latest
fi
fi

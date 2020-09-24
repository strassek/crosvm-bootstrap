#! /bin/bash

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

set -ex

BASE_DIRECTORY=${1} # Expected Directory Structure <basefolder>/rootfs.ext4, vmlinux, crosvm
SOURCES_DIRECTORY=${2}
XDG_RUNTIME_DIR=${3}
WAYLAND_DISPLAY=${4}
DISPLAY=${5}
CHANNEL=${6:-"--stable"}
TARGET=${7:-"--release"}
ACTION=${8:-"--run"}
SOURCE_DIRECTORY=${9:-""}
LOCAL_PWD=$PWD

LOCAL_KERNEL_CMD_OPTIONS=""
LOCAL_BUILD_TARGET=release
LOCAL_CHANNEL=stable

if [ $TARGET == "--release" ]; then
  LOCAL_KERNEL_CMD_OPTIONS="intel_iommu=on"
else
  LOCAL_KERNEL_CMD_OPTIONS="intel_iommu=on drm.debug=255 debug loglevel=8 initcall_debug"
  LOCAL_BUILD_TARGET=debug
fi

if [ $LOCAL_CHANNEL == "--dev" ]; then
  LOCAL_CHANNEL=dev
fi

# Handle component builds
mkdir -p $BASE_DIRECTORY/exec
mkdir -p $BASE_DIRECTORY/exec/scripts
mkdir -p $BASE_DIRECTORY/exec/start
mkdir -p $BASE_DIRECTORY/exec/stop
mkdir -p $BASE_DIRECTORY/exec/mount
mkdir -p $BASE_DIRECTORY/exec/lock
mkdir -p $BASE_DIRECTORY/exec/log
cp $SOURCES_DIRECTORY/launch/*.sh $BASE_DIRECTORY/exec/scripts/

source $BASE_DIRECTORY/exec/scripts/error_handler_internal.sh $BASE_DIRECTORY

docker image rm crosvm -f

if [ $ACTION == "--run" ]; then
if bash $BASE_DIRECTORY/exec/scripts/mount_internal.sh $BASE_DIRECTORY/rootfs.ext4 $BASE_DIRECTORY/mount; then
  echo “Preparing to launch crosvm...”
else
  echo “Failed to launch crosvm..., exit status: $?”
  exit 1
fi

cp $SOURCES_DIRECTORY/launch/docker/start.dockerfile $BASE_DIRECTORY/exec/start/Dockerfile
cd $BASE_DIRECTORY/exec/start
docker build -t crosvm:latest .
docker run -it --privileged -v /dev:/dev -v /proc:/proc -v /sys:/sys -v $BASE_DIRECTORY:/app/crosvm -v $BASE_DIRECTORY/mount:/app/intel crosvm:latest $XDG_RUNTIME_DIR $WAYLAND_DISPLAY $DISPLAY $LOCAL_CHANNEL $LOCAL_BUILD_TARGET $LOCAL_KERNEL_CMD_OPTIONS
else
mkdir -p $BASE_DIRECTORY/exec/stop
cp -v $SOURCES_DIRECTORY/launch/docker/stop.dockerfile $BASE_DIRECTORY/exec/stop/Dockerfile
cd $BASE_DIRECTORY/exec/stop
docker build -t crosvm:latest .
docker run -it --net=host --privileged -v /dev:/dev -v /proc:/proc -v /sys:/sys -v $BASE_DIRECTORY:/app/crosvm crosvm:latest
$BASE_DIRECTORY/exec/scripts/unmount_internal.sh $BASE_DIRECTORY/mount
rm -rf $BASE_DIRECTORY/exec
fi

cd $LOCAL_PWD


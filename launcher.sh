#! /bin/bash

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

set -ex

XDG_RUNTIME_DIR=${1}
WAYLAND_DISPLAY=${2}
DISPLAY=${3}
CHANNEL=${4:-"--stable"}
TARGET=${5:-"--release"}
ACTION=${6:-"--run"}

BASE_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
LOCAL_KERNEL_CMD_OPTIONS=""
LOCAL_BUILD_TARGET=release
LOCAL_CHANNEL=stable

if [ $TARGET == "--release" ]; then
  LOCAL_KERNEL_CMD_OPTIONS="intel_iommu=on drm.debug=255 debug loglevel=8 initcall_debug"
else
  LOCAL_KERNEL_CMD_OPTIONS="intel_iommu=on drm.debug=255 debug loglevel=8 initcall_debug"
  LOCAL_BUILD_TARGET=debug
fi

if [ $LOCAL_CHANNEL == "--dev" ]; then
  LOCAL_CHANNEL=dev
fi

if [ $ACTION == "--run" ]; then
	if [[ "$(sudo docker images -q intel-vm-start:latest 2> /dev/null)" == "" ]]; then
		if [[ "$(docker images -q intel_host:latest 2> /dev/null)" == "" ]]; then
			if mount | grep intel_host > /dev/null; then
				sudo umount -l intel_host
			fi
	
			echo "Preparing to create docker image...."
			if [ ! -e $BASE_DIRECTORY/images/rootfs_host.ext4 ]; then
				echo "Cannot find rootfs_host.ext4 file. Please check the build...."
				exit 1
			fi

			rm -rf intel_host
			mkdir intel_host
			sudo mount $BASE_DIRECTORY/images/rootfs_host.ext4 intel_host
			sudo tar -C intel_host -c . | sudo docker import - intel_host
			sudo umount -l intel_host
			rm -rf intel_host
		fi

		cd $BASE_DIRECTORY/docker/
		sudo docker build -t intel-vm-launch:latest -f Dockerfile-start .
	fi

exec sudo docker run -it --rm --privileged \
    --ipc=host \
    -e DISPLAY=$DISPLAY -e XDG_RUNTIME_DIR=/tmp -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
    -v /dev/log:/dev/log \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v /proc:/proc -v /sys:/sys \
    -v /$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:/tmp/$WAYLAND_DISPLAY:rw \
    -e container=docker \
    --mount type=bind,source=$BASE_DIRECTORY/images,target=/images \
    --mount type=bind,source=$BASE_DIRECTORY/launch/scripts,target=/scripts \
    --mount type=bind,source=$BASE_DIRECTORY/shared,target=/shared-host \
    intel-vm-launch:latest \
    $LOCAL_CHANNEL $LOCAL_BUILD_TARGET $LOCAL_KERNEL_CMD_OPTIONS

sudo docker rmi -f intel-vm-launch:latest
else
if [ $ACTION == "--stop" ]; then
  if [[ "$(sudo docker images -q intel-vm-stop 2> /dev/null)" != "" ]]; then
    sudo docker rmi -f intel-vm-stop:latest
  fi

  cd $BASE_DIRECTORY/docker/
  sudo docker build -t intel-vm-stop:latest -f Dockerfile-stop .
  exec sudo docker run -it --cap-add net_admin \
      --ipc=host \
      -e DISPLAY=$DISPLAY -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
      -v /dev/log:/dev/log \
      -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
      -v /proc:/proc -v /sys:/sys \
      -v /$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:/tmp/$WAYLAND_DISPLAY:rw \
      --mount type=bind,source=$BASE_DIRECTORY/images,target=/images \
      --mount type=bind,source=$BASE_DIRECTORY/launch/scripts,target=/scripts \
      --mount type=bind,source=$BASE_DIRECTORY/shared,target=/shared-host \
      intel-vm-stop:latest \
      $LOCAL_CHANNEL $LOCAL_BUILD_TARGET $LOCAL_KERNEL_CMD_OPTIONS

  sudo docker rmi -f intel-vm-stop:latest
fi
fi

#! /bin/bash

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

set -ex

GPU_PASSTHROUGH=${1:-"--false"}
XDG_RUNTIME_DIR=${2:-$XDG_RUNTIME_DIR}
WAYLAND_DISPLAY=${3:-$WAYLAND_DISPLAY}
DISPLAY=${4:-$DISPLAY}
CHANNEL=${5:-"--stable"}
TARGET=${6:-"--release"}
ACTION=${7:-"--run"}

BASE_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
LOCAL_BUILD_TARGET=release
LOCAL_CHANNEL=stable
LOCAL_PCI_CACHE=$(lspci -v | perl -anE '/VGA/i && $F[0] =~ /^[0-9a-f:.]+$/i && say $F[0]')
LOCAL_SERIAL_ID="0000"

if [ $TARGET == "--release" ]; then
  LOCAL_BUILD_TARGET=release
else
  LOCAL_BUILD_TARGET=debug
fi

if [ $LOCAL_CHANNEL == "--dev" ]; then
  LOCAL_CHANNEL=dev
fi

if [ $ACTION == "--run" ]; then

is_discrete() {
DEVICE_ID=${1}
if [[ "$DEVICE_ID" -eq "4905" ]] || [[ "$DEVICE_ID" -eq "4906" ]] || [[ "$DEVICE_ID" -eq "4907" ]] || [[ "$DEVICE_ID" -eq "4908" ]]; then
	echo "Discrete"
else
	echo "Integrated"
fi
}

get_device_id() {
SERIAL_NO=${1}
echo $(lspci -k -s $SERIAL_NO | perl -anE '/VGA/i && $F[0] =~ /^[0-9a-f:.]+$/i && say $F[7]')
}

get_vendor() {
SERIAL_NO=${1}
echo $(lspci -k -s $SERIAL_NO | perl -anE '/VGA/i && $F[0] =~ /^[0-9a-f:.]+$/i && say $F[4]')
}

is_bound() {
SERIAL_NO=${1}
if lspci -k -s $SERIAL_NO | grep "Kernel" > /dev/null
then
  echo true
else
  echo false
fi
}

enable_gpu_acceleration() {
local DEVICE_NO=0
local serial_no=0
echo "Supported Options on this platform:"
for g in $LOCAL_PCI_CACHE; do
  PCI_ID=$(get_device_id ${g})
  DEVICE_TYPE=$(is_discrete $PCI_ID)
  is_busy=$(is_bound ${g})
  vendor=$(get_vendor ${g})
  echo $vendor
  echo $DEVICE_TYPE
  if [[ "$vendor" == "Intel" ]] && [[ "$DEVICE_TYPE" == "Discrete" ]]; then
  	  DEVICE_NO=$((DEVICE_NO+1))
	  if [ ${g:0:5} == "0000:" ]; then
		serial_no=${g:5}
	  else
		serial_no=$g
	  fi
	  LOCAL_SERIAL_ID=0000:$serial_no
	  echo "$DEVICE_NO) PCI ID: $PCI_ID Device Type: $DEVICE_TYPE Vendor: $vendor Used by Host: $is_busy"
	  sudo $BASE_DIRECTORY/launch/scripts/setup_gpu_passthrough.sh bind $LOCAL_SERIAL_ID
  fi
done;	
}

# Handle PCI Passthrough checks.
if [[ "$GPU_PASSTHROUGH" == "--true" ]]; then
	enable_gpu_acceleration
fi

if [[ "$(sudo docker images -q intel-vm-start:latest 2> /dev/null)" == "" ]]; then
	if [[ "$(docker images -q intel_host:latest 2> /dev/null)" == "" ]]; then
		if mount | grep intel_host > /dev/null; then
			sudo umount -l intel_host
		fi
	
		echo "Preparing to create docker image...."
		if [ ! -e $BASE_DIRECTORY/images/rootfs_host.ext4 ]; then
			echo "Cannot find rootfs_host.ext4 file. Please check the environment...."
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
    $LOCAL_CHANNEL $LOCAL_BUILD_TARGET $GPU_PASSTHROUGH $LOCAL_SERIAL_ID

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
      $LOCAL_CHANNEL $LOCAL_BUILD_TARGET

  sudo docker rmi -f intel-vm-stop:latest
  if [[ -z $LOCAL_SERIAL_ID ]]; then
  	sudo $BASE_DIRECTORY/launch/scripts/setup_gpu_passthrough.sh unbind $LOCAL_SERIAL_ID
  fi
fi
fi

#! /bin/bash

###################################################################
#Stop running VM
###################################################################

###### exit on any script line that fails #########################
set -o errexit
###### bail on any unitialized variable reads #####################
set -o nounset
###### bail on failing commands before last pipe #################
set -o pipefail
###### Use this to ignore Errors for certian commands ###########
EXIT_CODE=0

######Globals ####################################################
GPU_PASSTHROUGH=${1:-"--false"}
XDG_RUNTIME_DIR=${2:-$XDG_RUNTIME_DIR}
WAYLAND_DISPLAY=${3:-$WAYLAND_DISPLAY}
DISPLAY=${4:-$DISPLAY}
CHANNEL=${5:-"--stable"}
TARGET=${6:-"--release"}
ACTION=${7:-"--run"}

LA_BASE_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
LA_LOCAL_BUILD_TARGET=release
LA_LOCAL_CHANNEL=stable
LA_LOCAL_PCI_CACHE=$(lspci -v | perl -anE '/VGA/i && $F[0] =~ /^[0-9a-f:.]+$/i && say $F[0]')
LA_LOCAL_SERIAL_ID="0000"

if [[ "$TARGET" == "--release" ]]; then
	LA_LOCAL_BUILD_TARGET=release
else
	LA_LOCAL_BUILD_TARGET=debug
fi

if [[ "$CHANNEL" == "--dev" ]]; then
	LA_LOCAL_CHANNEL=dev
fi

###############################################################################
##is_discrete()
###############################################################################
is_discrete() {
	DEVICE_ID=${1}
	if [[ "$DEVICE_ID" -eq "4905" ]] || [[ "$DEVICE_ID" -eq "4906" ]] || [[ "$DEVICE_ID" -eq "4907" ]] || [[ "$DEVICE_ID" -eq "4908" ]]; then
		echo "Discrete"
	else
		echo "Integrated"
	fi
}

###############################################################################
##get_device_id()
###############################################################################
get_device_id() {
	DEVICE_SERIAL_NO=${1}
	echo $(lspci -k -s $DEVICE_SERIAL_NO | perl -anE '/VGA/i && $F[0] =~ /^[0-9a-f:.]+$/i && say $F[7]')
}

###############################################################################
##get_vendor()
###############################################################################
get_vendor() {
	VENDOR_SERIAL_NO=${1}
	echo $(lspci -k -s $VENDOR_SERIAL_NO | perl -anE '/VGA/i && $F[0] =~ /^[0-9a-f:.]+$/i && say $F[4]')
}

###############################################################################
##is_bound()
###############################################################################
is_bound() {
	BOUND_SERIAL_NO=${1}
	if lspci -k -s $BOUND_SERIAL_NO | grep "Kernel" > /dev/null
	then
  		echo true
	else
  		echo false
	fi
}

###############################################################################
##enable_gpu_acceleration()
###############################################################################
enable_gpu_acceleration() {
	local DEVICE_NO=0
	local serial_no=0
	echo "Supported Options on this platform:"
	for g in $LA_LOCAL_PCI_CACHE; do
  		PCI_ID=$(get_device_id ${g})
  		DEVICE_TYPE=$(is_discrete $PCI_ID)
  		is_busy=$(is_bound ${g})
  		vendor=$(get_vendor ${g})
  		if [[ "$vendor" == "Intel" ]] && [[ "$DEVICE_TYPE" == "Discrete" ]]; then
  	  		DEVICE_NO=$((DEVICE_NO+1))
	  		if [[ "${g:0:5}" == "0000:" ]]; then
				serial_no=${g:5}
	  		else
				serial_no=$g
	  		fi
	  	
	  		LA_LOCAL_SERIAL_ID=0000:$serial_no
	  		echo "$DEVICE_NO) PCI ID: $PCI_ID Device Type: $DEVICE_TYPE Vendor: $vendor Used by Host: $is_busy"
	  		sudo $LA_BASE_DIRECTORY/launch/scripts/setup_gpu_passthrough.sh bind $LA_LOCAL_SERIAL_ID
  		fi
	done;	
}

###############################################################################
##main()
###############################################################################
if [[ "$ACTION" == "--run" ]]; then
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
			if [ ! -e $LA_BASE_DIRECTORY/images/rootfs_host.ext4 ]; then
				echo "Cannot find rootfs_host.ext4 file. Please check the environment...."
				exit 1
			fi

			rm -rf intel_host
			mkdir intel_host
			sudo mount $LA_BASE_DIRECTORY/images/rootfs_host.ext4 intel_host
			sudo tar -C intel_host -c . | sudo docker import - intel_host
			sudo umount -l intel_host
			rm -rf intel_host
		fi

		cd $LA_BASE_DIRECTORY/docker/
		sudo docker build -t intel-vm-launch:latest -f Dockerfile-start .
	fi

	LA_LOCAL_GPU_PASSTHROUGH=$GPU_PASSTHROUGH
	if [[ "$LA_LOCAL_SERIAL_ID" == "0000" ]]; then
		LA_LOCAL_GPU_PASSTHROUGH=--false
	fi

	exec sudo docker run -it --rm --privileged \
    		--ipc=host \
    		-e DISPLAY=$DISPLAY -e XDG_RUNTIME_DIR=/tmp -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
    		-v /dev/log:/dev/log \
    		-v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    		-v /proc:/proc -v /sys:/sys \
    		-v /$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:/tmp/$WAYLAND_DISPLAY:rw \
    		-e container=docker \
    		--mount type=bind,source=$LA_BASE_DIRECTORY/images,target=/images \
    		--mount type=bind,source=$LA_BASE_DIRECTORY/launch/scripts,target=/scripts \
    		--mount type=bind,source=$LA_BASE_DIRECTORY/shared,target=/shared-host \
    		intel-vm-launch:latest \
    		$LA_LOCAL_CHANNEL $LA_LOCAL_BUILD_TARGET $LA_LOCAL_GPU_PASSTHROUGH $LA_LOCAL_SERIAL_ID

	sudo docker rmi -f intel-vm-launch:latest
	if [[ "$LA_LOCAL_SERIAL_ID" != "0000" ]]; then
		sudo $LA_BASE_DIRECTORY/launch/scripts/setup_gpu_passthrough.sh unbind $LA_LOCAL_SERIAL_ID
	fi
else
	if [ $ACTION == "--stop" ]; then
		if [[ "$(sudo docker images -q intel-vm-stop 2> /dev/null)" != "" ]]; then
    			sudo docker rmi -f intel-vm-stop:latest
  		fi

  		cd $LA_BASE_DIRECTORY/docker/
  		sudo docker build -t intel-vm-stop:latest -f Dockerfile-stop .
  		exec sudo docker run -it --cap-add net_admin \
      			--ipc=host \
      			-e DISPLAY=$DISPLAY -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
      			-v /dev/log:/dev/log \
      			-v /tmp/.X11-unix:/tmp/.X11-unix:rw \
      			-v /proc:/proc -v /sys:/sys \
      			-v /$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:/tmp/$WAYLAND_DISPLAY:rw \
      			--mount type=bind,source=$LA_BASE_DIRECTORY/images,target=/images \
      			--mount type=bind,source=$LA_BASE_DIRECTORY/launch/scripts,target=/scripts \
      			--mount type=bind,source=$LA_BASE_DIRECTORY/shared,target=/shared-host \
      			intel-vm-stop:latest \
      			$LA_LOCAL_CHANNEL $LA_LOCAL_BUILD_TARGET

  		sudo docker rmi -f intel-vm-stop:latest
	fi
fi

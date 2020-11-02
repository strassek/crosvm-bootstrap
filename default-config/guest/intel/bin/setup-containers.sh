#! /bin/bash

# setup-containers.sh

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

name='game-fast-container'
C_LOCAL_USER=$(whoami)
cd /intel/shared-host/containers

echo "Preparing to launch container...."
echo "User:" $C_LOCAL_USER

if [[ -e game-fast-container.gz ]]; then
	echo "Importing from stored container image..."
	zcat game-fast-container.gz | docker import - game-fast-container
else
	if [[ $(docker ps -a -f "name=$name" --format '{{.Names}}') == $name ]]; then
		if [[ "$(docker images -q game-fast:latest 2> /dev/null)" != "" ]]; then
    			if [[ "$(docker images -q game-fast:previous-tag 2> /dev/null)" != "" ]]; then
      				docker rmi -f game-fast:previous-tag || true
    			fi
    
    			docker image tag game-fast:latest game-fast:previous-tag
    			docker rmi -f game-fast:latest || true
  		fi

  		docker commit game-fast-container game-fast:latest
  		docker rm -v game-fast-container
	fi
  
	if [[ ! -e rootfs_game_fast.ext4 ]]; then
		if [[ "$(docker images -q game-fast 2> /dev/null)" == "" ]]; then
    			echo "You are missing Game-Fast Container. Please install the container."
    			exit 1
  		fi
	else
		if [[ "$(docker images -q game-fast 2> /dev/null)" != "" ]]; then
  			docker rmi -f game-fast:latest
		fi

		if mount | grep intel_drivers > /dev/null; then
  			sudo umount -l intel_drivers
		fi

		if mount | grep game_fast > /dev/null; then
  			sudo umount -l game_fast
		fi
		
		echo "Creating new container image..."
		sudo rm -rf game_fast || true
		sudo mkdir game_fast
		sudo mount rootfs_game_fast.ext4 game_fast
		sudo tar -C game_fast -c . | docker import - game-fast:latest
		sudo umount -l game_fast
		sudo rm -rf game_fast
	fi
fi

echo "Container image ready."
exec docker run -t -i -d -e BASH_ENV=/etc/profile --name game-fast-container -e container=docker --privileged -h game-fast --storage-opt size=120G -u $C_LOCAL_USER -v /dev:/dev -v /opt:/opt -v /intel/bin/container:/intel/bin -v /intel/env:/intel/env -e XDG_RUNTIME_DIR=/run/user/${UID} -v /tmp/.X11-unix:/tmp/.X11-unix:rw --mount type=bind,source=/intel/shared-host/guest,target=/shared -e XDG_CONFIG_DIRS=/etc/xdg/xdg-ubuntu-wayland:/etc/xdg -e DESKTOP_SESSION=ubuntu-wayland -e XDG_DATA_DIRS=/usr/share/ubuntu-wayland:/usr/local/share/:/usr/share/:/var/lib/snapd/desktop -e DISPLAY=:0 -e PATH=/intel/bin:$PATH game-fast:latest bash --login

if [[ "$(docker images -q game-fast:previous-tag 2> /dev/null)" != "" ]]; then
	docker rmi -f game-fast:previous-tag || true
fi

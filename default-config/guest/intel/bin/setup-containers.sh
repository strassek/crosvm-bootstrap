#! /bin/bash

# setup-containers.sh

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

name='game-fast-container'
cd /intel/containers
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
  
if [[ ! -e rootfs_common.ext4 ]] && [[ ! -e rootfs_game_fast.ext4 ]]; then
  if [[ "$(docker images -q game-fast 2> /dev/null)" == "" ]]; then
    echo "You are missing Game-Fast Container. Please install the container."
    exit 1
  fi

  echo "You are running the latest Game-Fast release."
  exec docker run -t -i -d -e BASH_ENV=/etc/profile --name game-fast-container -e container=docker --privileged -h game-fast --storage-opt size=120G -u $(whoami) -v /dev:/dev -e XDG_RUNTIME_DIR=/run/user/${UID} -v /tmp/.X11-unix:/tmp/.X11-unix:rw -e DISPLAY=:0 -e PATH=/intel/bin:$PATH game-fast:latest bash --login
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

rm -rf game_fast || true
mkdir game_fast
sudo mount rootfs_game_fast.ext4 game_fast
sudo tar -C game_fast -c . | docker import - game-fast:latest
sudo umount -l game_fast
rm -rf game_fast
rm *.ext4

exec docker run -t -i -d -e BASH_ENV=/etc/profile --name game-fast-container -e container=docker --privileged -h game-fast --storage-opt size=120G -u $(whoami) -v /dev:/dev -e XDG_RUNTIME_DIR=/run/user/${UID} -v /tmp/.X11-unix:/tmp/.X11-unix:rw -e DISPLAY=:0 -e PATH=/intel/bin:$PATH game-fast:latest bash --login
fi

if [[ "$(docker images -q game-fast:previous-tag 2> /dev/null)" != "" ]]; then
  docker rmi -f game-fast:previous-tag || true
fi

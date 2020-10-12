#! /bin/bash

# setup-containers.sh
# Set up build environment for docker container that generates Debian rootfs
# then calls docker build.

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

cd /intel/containers
if [ -z rootfs_common.ext4 ]; then
  echo "unable to find driver image."
  exit 1;
fi

if [ -z rootfs_game_fast.ext4 ]; then
  echo "unable to find Game-Fast image."
  exit 1;
fi

if [[ "$(docker images -q game-fast 2> /dev/null)" != "" ]]; then
  docker rmi -f game-fast:latest
fi

if [[ "$(docker images -q intel-drivers 2> /dev/null)" != "" ]]; then
  docker rmi -f intel-drivers:latest
fi

if mount | grep intel_drivers > /dev/null; then
  sudo umount -l intel_drivers
fi

if mount | grep game_fast > /dev/null; then
  sudo umount -l game_fast
fi

rm -rf intel_drivers || true
mkdir intel_drivers
sudo mount rootfs_common.ext4 intel_drivers
sudo tar -C intel_drivers -c . | docker import - intel-drivers:latest
sudo umount -l intel_drivers
rm -rf intel_drivers

rm -rf game_fast || true
mkdir game_fast
sudo mount rootfs_game_fast.ext4 game_fast
sudo tar -C game_fast -c . | docker import - game-fast:latest
sudo umount -l game_fast
rm -rf game_fast

rm *.ext4

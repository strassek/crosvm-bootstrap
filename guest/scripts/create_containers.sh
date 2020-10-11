if [[ "$(docker images -q game_fast 2> /dev/null)" != "" ]]; then
  docker rmi -f game_fast:latest
fi

if [[ "$(docker images -q intel-drivers 2> /dev/null)" != "" ]]; then
  docker rmi -f intel-drivers:latest
fi

cd /containers
mkdir game_fast
sudo mount rootfs_game_fast.ext4 game_fast
sudo tar -C game_fast -c . | docker import - game_fast:latest
sudo umount -l game_fast
rm rootfs_game_fast.ext4
rm -rf game_fast

mkdir intel_drivers
sudo mount roots_common.ext4 intel_drivers
sudo tar -C intel_drivers -c . | docker import - intel_drivers:latest
sudo umount -l intel_drivers
rm roots_common.ext4
rm -rf intel_drivers
echo "containers created"

#! /bin/bash

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

CHANNEL=${1}
TARGET=${2}
KERNEL_CMD_OPTIONS=${3}
ACTION=${4}

LOCAL_EXEC_DIRECTORY=/opt/$CHANNEL/$TARGET/x86_64/bin # Expected Directory Structure <basefolder>/rootfs.ext4, vmlinux <basefolder>/<channel>/<build target>/crosvm

pwd="${PWD}"

GPU="width=1024,height=768,backend=2d,glx=true --x-display=:0.0"
echo "X Display:" $DISPLAY
echo "Wayland Display:" $WAYLAND_DISPLAY
echo "XDG_RUNTIME_DIR:" $XDG_RUNTIME_DIR
echo "EXEC_DIRECTORY" $LOCAL_EXEC_DIRECTORY
echo "KERNEL_CMD_OPTIONS" $KERNEL_CMD_OPTIONS
echo "ACTION" $ACTION

# Generate random MAC address
genMAC () {
  hexchars="0123456789ABCDEF"
  end=$( for i in {1..8} ; do echo -n ${hexchars:$(( $RANDOM % 16 )):1} ; done | sed -e 's/\(..\)/:\1/g' )
  echo "FE:05$end"
}

LOCAL_INTEL_LIB_BASELINE=/opt/$CHANNEL/$TARGET/x86_64

LOCAL_LIBRARY_PATH=$LOCAL_INTEL_LIB_BASELINE/lib:$LOCAL_INTEL_LIB_BASELINE/lib/x86_64-linux-gnu:/lib:/lib/x86_64-linux-gnu

echo "LD LIBRARY PATH:" $LOCAL_LIBRARY_PATH $(genMAC)

/bin/bash /scripts/exec/ip_tables.sh eth0 vmtap0

LD_LIBRARY_PATH=$LOCAL_LIBRARY_PATH $LOCAL_EXEC_DIRECTORY/crosvm $ACTION --disable-sandbox --rwdisk /images/rootfs_guest.ext4 -s /images/crosvm.sock -m 10240 --cpus 4 -p "root=/dev/vda" -p "$KERNEL_CMD_OPTIONS" -p "console=hvc0" --host_ip 10.0.0.1 --netmask 255.255.255.0 --mac $(genMAC) --wayland-sock=$WAYLAND_DISPLAY --gpu egl=true,glx=true,gles=true --x-display=$DISPLAY --wayland-dmabuf  --serial type=stdout,hardware=virtio-console,num=1 /images/vmlinux

#! /bin/bash

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

XDG_RUNTIME_DIR=${1}
WAYLAND_DISPLAY=${2}
DISPLAY=${3}
CHANNEL=${4}
TARGET=${5}
KERNEL_CMD_OPTIONS=${6}

LOCAL_EXEC_DIRECTORY=/app/crosvm # Expected Directory Structure <basefolder>/rootfs.ext4, vmlinux <basefolder>/<channel>/<build target>/crosvm

pwd="${PWD}"

GPU="width=1024,height=768,backend=2d,glx=true --x-display=:0.0"
echo "X Display:" $DISPLAY
echo "Wayland Display:" $WAYLAND_DISPLAY
echo "XDG_RUNTIME_DIR:" $XDG_RUNTIME_DIR
echo "EXEC_DIRECTORY" $LOCAL_EXEC_DIRECTORY
echo "KERNEL_CMD_OPTIONS" $KERNEL_CMD_OPTIONS

# Generate random MAC address
genMAC () {
  hexchars="0123456789ABCDEF"
  end=$( for i in {1..8} ; do echo -n ${hexchars:$(( $RANDOM % 16 )):1} ; done | sed -e 's/\(..\)/:\1/g' )
  echo "FE:05$end"
}

LOCAL_INTEL_LIB_BASELINE=/app/intel/opt/$CHANNEL/$TARGET/x86_64

LOCAL_LIBRARY_PATH=$LOCAL_INTEL_LIB_BASELINE/vm/lib:$LOCAL_INTEL_LIB_BASELINE/vm/lib/x86_64-linux-gnu:$LOCAL_INTEL_LIB_BASELINE/lib/x86_64-linux-gnu:$LOCAL_INTEL_LIB_BASELINE/lib:/app/intel/lib:/app/intel/lib/x86_64-linux-gnu

echo "LD LIBRARY PATH:" $LOCAL_LIBRARY_PATH

LD_LIBRARY_PATH=$LOCAL_LIBRARY_PATH $LOCAL_EXEC_DIRECTORY/crosvm run --disable-sandbox --rwdisk $LOCAL_EXEC_DIRECTORY/rootfs.ext4 -s $LOCAL_EXEC_DIRECTORY/exec/lock/crosvm.sock -m 10240 --cpus 4 -p "root=/dev/vda" -p "$KERNEL_CMD_OPTIONS" --ipc=host --wayland-sock=$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY --gpu egl=true,glx=true,gles=true --x-display=$DISPLAY --wayland-dmabuf -e DISPLAY=$DISPLAY -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR $LOCAL_EXEC_DIRECTORY/vmlinux

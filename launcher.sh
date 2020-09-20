#! /bin/bash

XDG_RUNTIME_DIR=$1
WAYLAND_DISPLAY=$2
X_DISPLAY=$3
TARGET=${4:-"--release"}
CHANNEL=${5:-"--stable"}
STOP=${6:-"--run"}
CUSTOM_PATH=${7:-""}
LOCAL_CURRENT_CHANNEL=stable
LOCAL_BUILD_TARGET=release
KERNEL_CMD_OPTIONS="intel_iommu=on"

if [ $CHANNEL == "--stable" ]; then
  LOCAL_CURRENT_CHANNEL=stable
else
  LOCAL_CURRENT_CHANNEL=dev
fi

if [ $TARGET == "--release" ]; then
  LOCAL_BUILD_TARGET=release
  KERNEL_CMD_OPTIONS="intel_iommu=on"
else
  LOCAL_BUILD_TARGET=debug
  KERNEL_CMD_OPTIONS="intel_iommu=on drm.debug=255 debug loglevel=8 initcall_debug"
fi
FINAL_PATH=$PWD/build/output/$LOCAL_CURRENT_CHANNEL/$LOCAL_BUILD_TARGET
if [ $CUSTOM_PATH != "" ]; then
  FINAL_PATH=$CUSTOM_PATH
fi

export CURRENT_CHANNEL=$LOCAL_CURRENT_CHANNEL

GPU="width=1024,height=768,backend=2d,glx=true --x-display=:0.0"
echo "X Display:" $DISPLAY
echo "Wayland Display:" $WAYLAND_DISPLAY
echo "XDG_RUNTIME_DIR:" $XDG_RUNTIME_DIR
echo "CrosVM Path" $PWD/build/output/$LOCAL_CURRENT_CHANNEL/$LOCAL_BUILD_TARGET/crosvm

if [ $STOP == "--stop" ]; then
  sudo LD_LIBRARY_PATH=$FINAL_PATH $FINAL_PATH/crosvm stop $FINAL_PATH/crosvm.sock
else
    sudo LD_LIBRARY_PATH=$FINAL_PATH --preserve-env=$CURRENT_CHANNEL $FINAL_PATH/crosvm run --disable-sandbox --rwdisk $PWD/build/output/rootfs.ext4 -s $FINAL_PATH/crosvm.sock -m 10240 --cpus 4 -p "root=/dev/vda" -p "$KERNEL_CMD_OPTIONS" --host_ip 10.0.0.1 --netmask 255.255.255.0 --mac 9C:B6:D0:E3:96:4D --wayland-sock=$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY --gpu egl=true,glx=true,gles=true --x-display=$DISPLAY --wayland-dmabuf $PWD/build/output/$LOCAL_CURRENT_CHANNEL/vmlinux
fi

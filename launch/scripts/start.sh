#! /bin/bash

###################################################################
#Launch VM.
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

CHANNEL=${1}
TARGET=${2}
GPU_PASS_THROUGH=${3}
SERIAL_ID=${4}

LOCAL_EXEC_DIRECTORY=/opt/$CHANNEL/$TARGET/x86_64/bin
LOCAL_KERNEL_CMD_OPTIONS=""
LOCAL_ACCELERATION_OPTION="--gpu egl=true,glx=true,gles=true"

if [[ "$TARGET" != "debug" ]]; then
	LOCAL_KERNEL_CMD_OPTIONS="intel_iommu=on drm.debug=255 debug loglevel=2"
else
	LOCAL_KERNEL_CMD_OPTIONS="intel_iommu=on drm.debug=255 debug loglevel=8 initcall_debug"
fi

if [[ "$GPU_PASS_THROUGH" == "--true" ]]; then
	LOCAL_ACCELERATION_OPTION="--vfio /sys/bus/pci/devices/$SERIAL_ID"
fi

pwd="${PWD}"

GPU="width=1024,height=768,backend=2d,glx=true --x-display=:0.0"
echo "X Display:" $DISPLAY
echo "Wayland Display:" $WAYLAND_DISPLAY
echo "XDG_RUNTIME_DIR:" $XDG_RUNTIME_DIR
echo "EXEC_DIRECTORY" $LOCAL_EXEC_DIRECTORY
echo "KERNEL_CMD_OPTIONS" $LOCAL_KERNEL_CMD_OPTIONS
echo "ACCELERATION_OPTION" $LOCAL_ACCELERATION_OPTION

LOCAL_INTEL_LIB_BASELINE=/opt/$CHANNEL/$TARGET/x86_64
LOCAL_LIBRARY_PATH=$LOCAL_INTEL_LIB_BASELINE/lib:$LOCAL_INTEL_LIB_BASELINE/lib/x86_64-linux-gnu:/lib:/lib/x86_64-linux-gnu

###############################################################################
##genMAC()
###############################################################################
# Generate random MAC address
genMAC () {
	hexchars="0123456789ABCDEF"
	end=$( for i in {1..8} ; do echo -n ${hexchars:$(( $RANDOM % 16 )):1} ; done | sed -e 's/\(..\)/:\1/g' )
	echo "FE:05$end"
}

###############################################################################
##main()
###############################################################################
/bin/bash /scripts/ip_tables.sh eth0 vmtap0
systemctl start dptf.service
echo "DPTF Service started"

export MESA_LOADER_DRIVER_OVERRIDE=iris
export MESA_LOG_LEVEL=debug
export EGL_LOG_LEVEL=debug 
#drm.debug=255 debug loglevel=8

EGL_LOG_LEVEL=debug MESA_LOG_LEVEL=debug MESA_LOADER_DRIVER_OVERRIDE=iris LD_LIBRARY_PATH=$LOCAL_LIBRARY_PATH $LOCAL_EXEC_DIRECTORY/crosvm run --disable-sandbox $LOCAL_ACCELERATION_OPTION --rwdisk /images/rootfs_guest.ext4 -s /images/crosvm.sock -m 10240 --cpus 4 --host_ip 10.0.0.1 --serial type=stdout,hardware=virtio-console,num=1,console=true,earlycon=false,stdin=true --shared-dir "/shared-host:shared-host:type=p9:cache=auto:writeback=true"  -p "$LOCAL_KERNEL_CMD_OPTIONS" -p "root=/dev/vda" --netmask 255.255.255.0 --mac $(genMAC) --wayland-sock=/tmp/$WAYLAND_DISPLAY --wayland-dmabuf --x-display=$DISPLAY /images/vmlinux

systemctl stop dptf.service

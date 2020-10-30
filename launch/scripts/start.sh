#! /bin/bash

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

CHANNEL=${1}
TARGET=${2}
ENABLE_GPU_PASSTHROUGH=${3}
KERNEL_CMD_OPTIONS=${4}

LOCAL_EXEC_DIRECTORY=/opt/$CHANNEL/$TARGET/x86_64/bin
LOCAL_PCI_CACHE=$(lspci -v | perl -anE '/VGA/i && $F[0] =~ /^[0-9a-f:.]+$/i && say $F[0]')
LOCAL_SERIAL_ID=""
ACCELERATION_OPTION="--gpu egl=true,glx=true,gles=true"

pwd="${PWD}"

echo "ENABLE_GPU_PASSTHROUGH" $ENABLE_GPU_PASSTHROUGH

GPU="width=1024,height=768,backend=2d,glx=true --x-display=:0.0"
echo "X Display:" $DISPLAY
echo "Wayland Display:" $WAYLAND_DISPLAY
echo "XDG_RUNTIME_DIR:" $XDG_RUNTIME_DIR
echo "EXEC_DIRECTORY" $LOCAL_EXEC_DIRECTORY
echo "KERNEL_CMD_OPTIONS" $KERNEL_CMD_OPTIONS

LOCAL_INTEL_LIB_BASELINE=/opt/$CHANNEL/$TARGET/x86_64
LOCAL_LIBRARY_PATH=$LOCAL_INTEL_LIB_BASELINE/lib:$LOCAL_INTEL_LIB_BASELINE/lib/x86_64-linux-gnu:/lib:/lib/x86_64-linux-gnu

# Generate random MAC address
genMAC () {
  hexchars="0123456789ABCDEF"
  end=$( for i in {1..8} ; do echo -n ${hexchars:$(( $RANDOM % 16 )):1} ; done | sed -e 's/\(..\)/:\1/g' )
  echo "FE:05$end"
}

is_discrete() {
DEVICE_ID=${1}
if [ $DEVICE_ID == "4905" ] || [ $DEVICE_ID == "4906" ] || [ $DEVICE_ID == "4907" ] || [$DEVICE_ID == "4908" ]; then
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
  DEVICE_NO=$((DEVICE_NO+1))
  if [ $vendor == "Intel" ] && [ $DEVICE_TYPE == "Discrete" ]; then
	  if [ ${g:0:5} == "0000:" ]; then
		serial_no=${g:5}
	  else
		serial_no=$g
	  fi
	  echo "$DEVICE_NO) PCI ID: $PCI_ID Device Type: $DEVICE_TYPE Vendor: $vendor Used by Host: $is_busy"
	  /bin/bash  /scripts/setup_gpu_passthrough.sh bind $serial_no
	  ACCELERATION_OPTION="--vfio /sys/bus/pci/devices/0000:$serial_no"
  else
	  echo "None of the PCI devices are Intel & Discrete"
  fi
done;
}

/bin/bash /scripts/ip_tables.sh eth0 vmtap0
systemctl start dptf.service
echo "DPTF Service started"

# Handle PCI Passthrough checks.
if [[ "$ENABLE_GPU_PASSTHROUGH" == "--true" ]]; then
	enable_gpu_acceleration
fi

export MESA_LOADER_DRIVER_OVERRIDE=iris
export MESA_LOG_LEVEL=debug
export EGL_LOG_LEVEL=debug 
#drm.debug=255 debug loglevel=8

EGL_LOG_LEVEL=debug MESA_LOG_LEVEL=debug MESA_LOADER_DRIVER_OVERRIDE=iris LD_LIBRARY_PATH=$LOCAL_LIBRARY_PATH $LOCAL_EXEC_DIRECTORY/crosvm run --disable-sandbox $ACCELERATION_OPTION --rwdisk /images/rootfs_guest.ext4 -s /images/crosvm.sock -m 10240 --cpus 4 -p "intel_iommu=on" --host_ip 10.0.0.1 --serial type=stdout,hardware=virtio-console,num=1,console=true,earlycon=false,stdin=true --shared-dir "/shared-host:shared-host:type=p9:cache=auto:writeback=true"  -p "root=/dev/vda" --netmask 255.255.255.0 --mac $(genMAC) --wayland-sock=/tmp/$WAYLAND_DISPLAY --wayland-dmabuf --x-display=$DISPLAY /images/vmlinux

if [[ -z $LOCAL_SERIAL_ID ]]; then
  /bin/bash /scripts/setup_gpu_passthrough.sh unbind $LOCAL_SERIAL_ID
fi

systemctl stop dptf.service

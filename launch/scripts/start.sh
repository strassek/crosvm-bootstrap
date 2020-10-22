#! /bin/bash

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

CHANNEL=${1}
TARGET=${2}
KERNEL_CMD_OPTIONS=${3}

LOCAL_EXEC_DIRECTORY=/opt/$CHANNEL/$TARGET/x86_64/bin
LOCAL_PCI_CACHE=$(lspci -v | perl -anE '/VGA/i && $F[0] =~ /^[0-9a-f:.]+$/i && say $F[0]')
LOCAL_SERIAL_ID=""
ACCELERATION_OPTION=""

pwd="${PWD}"

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
if [ $DEVICE_ID == "4905" ]; then
  echo "Discrete."
else
  echo "Integrated."
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
echo "Supported Options on this platform:"
for g in $LOCAL_PCI_CACHE; do
  PCI_ID=$(get_device_id ${g})
  DEVICE_TYPE=$(is_discrete $PCI_ID)
  is_busy=$(is_bound ${g})
  vendor=$(get_vendor ${g})
  if [ $vendor != "Intel" ]; then
    echo "Skipping device with PCI ID: $PCI_ID" $vendor
    continue;
  fi
  
  if [ -z $PCI_ID ]; then
    continue;
  fi
  
  DEVICE_NO=$((DEVICE_NO+1))
  echo "$DEVICE_NO) PCI ID: $PCI_ID Device Type: $DEVICE_TYPE Vendor: $vendor Used by Host: $is_busy"
done;

VIRTIO_CHOICE=0
EXIT_CHOICE=0
if [ $DEVICE_NO != 0 ] && [ $DEVICE_NO != 1 ]; then
DEVICE_NO=$((DEVICE_NO+1))
VIRTIO_CHOICE=$DEVICE_NO
echo "$DEVICE_NO) Accelerated rendering support using Virtio."
DEVICE_NO=$((DEVICE_NO+1))
echo "$DEVICE_NO) Software rendering support using Virtio."
DEVICE_NO=$((DEVICE_NO+1))
EXIT_CHOICE=$DEVICE_NO
echo "$DEVICE_NO) Exit."
fi

read -p 'Choose between [1-$DEVICE_NO] followed by [ENTER]: ' num
if [ $num -gt $DEVICE_NO ] || [ $num -le 0 ]; then
  echo "Invalid Option."
  exit 0;
fi 

if [ $num -eq $EXIT_CHOICE ]; then
  exit 0;
fi 

if [ $num -lt $VIRTIO_CHOICE ]; then
  LOCAL_SERIAL_ID=$(/bin/bash /scripts/setup_gpu_passthrough.sh bind $num)
  ACCELERATION_OPTION="--vfio /sys/bus/pci/devices/$LOCAL_SERIAL_ID"
else
  if [ $num -eq $VIRTIO_CHOICE ]; then
    ACCELERATION_OPTION="--gpu egl=true,glx=true,gles=true"
    LOCAL_SERIAL_ID=""
  else
    ACCELERATION_OPTION=""
    LOCAL_SERIAL_ID=""
  fi 
fi 
}

/bin/bash /scripts/ip_tables.sh eth0 vmtap0

# Handle PCI Passthrough checks.
enable_gpu_acceleration

export MESA_LOADER_DRIVER_OVERRIDE=iris
export MESA_LOG_LEVEL=debug
export EGL_LOG_LEVEL=debug 
#drm.debug=255 debug loglevel=8

EGL_LOG_LEVEL=debug MESA_LOG_LEVEL=debug MESA_LOADER_DRIVER_OVERRIDE=iris LD_LIBRARY_PATH=$LOCAL_LIBRARY_PATH $LOCAL_EXEC_DIRECTORY/crosvm run --disable-sandbox $ACCELERATION_OPTION --rwdisk /images/rootfs_guest.ext4 -s /images/crosvm.sock -m 10240 --cpus 4 -p "root=/dev/vda" -p "intel_iommu=on" --host_ip 10.0.0.1 --netmask 255.255.255.0 --mac $(genMAC) --wayland-sock=/tmp/$WAYLAND_DISPLAY --wayland-dmabuf --x-display=$DISPLAY /images/vmlinux

if [[ -z $LOCAL_SERIAL_ID ]]; then
  /bin/bash /scripts/setup_gpu_passthrough.sh unbind $LOCAL_SERIAL_ID
fi

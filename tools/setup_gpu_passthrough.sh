#! /bin/bash
# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

BIND_DEVICE=${1}

CACHE=$(lspci -v | perl -anE '/VGA/i && $F[0] =~ /^[0-9a-f:.]+$/i && say $F[0]')

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

load_vifio_modules() {
modprobe vfio
modprobe vfio_iommu_type1
modprobe vfio_pci
}

find_iommu_group() {
SERIAL_NO=${1}
for g in /sys/kernel/iommu_groups/*; do
  n=${g##*/}
  found_group=false
  for d in $g/devices/*; do
    local DEVICE_SERIAL_NO=$(lspci -nns ${d##*/} | perl -anE '/VGA/i && $F[0] =~ /^[0-9a-f:.]+$/i && say $F[0]')
    if [ "$SERIAL_NO" == "$DEVICE_SERIAL_NO" ]; then
      found_group=true
    else
      found_group=false
    fi
    
    if [ $found_group == "true" ]; then
      break
    fi
  done
  if [ $found_group == "true" ]; then
    echo $n
    break
  fi
done
}

remove_brackets() {
DEVICE_ID=${1}
echo $("$DEVICE_ID" | sed -e 's/^[//' -e 's/]$//')
}

bind_iommu_group() {
GROUP_NO=${1}
for g in /sys/kernel/iommu_groups/*; do
  n=${g##*/}
  if [ $GROUP_NO == $n ]; then
    local total_devices=0
    for d in $g/devices/*; do
      total_devices=$((total_devices+1))
    done;
    
    if [ $total_devices == 0 ]; then
      echo "Couldnot find the device info. Please check that you have IOMMU support setup correctly. Check /sys/kernel/iommu_groups/"
    fi
    
    if [ $total_devices != 1 ]; then
      echo "The following devices share the same IOMMU group and need to be passed through to VM."
      for d in $g/devices/*; do
        echo -e "\t$(lspci -nns ${d##*/})"
        total_devices=$((total_devices+1))
      done;
      echo "Press Y followed by [ENTER] to bind these devices to VM:"
      read option
      if [ "$option" == "N" ] || [ "$option" == "n" ]; then
        echo "GPU Pass through cannot be enabled without re-binding all these devices to VM. Please re-run the setup to enable GPU Pass through support."
        exit 0
      else
        if [ "$option" != "Y" ] && [ "$option" != "y" ]; then
          echo "Invalid choice. Quitting..."
          exit 0
        fi
      fi
    fi
    
    for d in $g/devices/*; do
      if [ -e /sys/bus/pci/drivers/vfio-pci ]; then
        local serial_no=$(lspci -nns ${d##*/} | perl -anE '$F[0] =~ /^[0-9a-f:.]+$/i && say $F[0]')
        local vfio_id=$(lspci -nns ${d##*/} | perl -anE '$F[0] =~ /^[0-9a-f:.]+$/i && say $F[8]')
        vfio_id=${vfio_id#?};
        vfio_id=$(echo $vfio_id | cut -f1 -d":")
        local read_link=$(readlink /sys/bus/pci/devices/"$serial_no"/driver)
        local current_driver=$(basename $read_link)
        if [[ $current_driver == "vfio-pci" ]]; then
          continue;
        fi
  
        echo "current_driver" $current_driver
        local pci_id=$(get_device_id ${serial_no})
        if [ -z $pci_id ]; then
          continue;
          
        echo -e "Hiding \t$(lspci -nns ${d##*/})"
        echo "$vfio_id" "$pci_id" > /sys/bus/pci/drivers/vfio-pci/new_id
        echo "$serial_no" > /sys/bus/pci/devices/"$serial_no"/driver/unbind
        echo "$serial_no" > /sys/bus/pci/drivers/vfio-pci/bind
      fi
    done
  fi
done
}

unbind_iommu_group() {
GROUP_NO=${1}
for g in /sys/kernel/iommu_groups/*; do
  n=${g##*/}
  if [ $GROUP_NO == $n ]; then
    local total_devices=0
    for d in $g/devices/*; do
      total_devices=$((total_devices+1))
    done;
    
    for d in $g/devices/*; do
      if [ -e /sys/bus/pci/drivers/vfio-pci ]; then
        echo -e "Unbinding \t$(lspci -nns ${d##*/})"
        local serial_no=$(lspci -nns ${d##*/} | perl -anE '$F[0] =~ /^[0-9a-f:.]+$/i && say $F[0]')
        local read_link=$(readlink /sys/bus/pci/devices/"$serial_no"/driver)
        local current_driver=$(basename $read_link)
        if [ $current_driver != "vfio-pci" ]; then
          continue;
        fi
        
        local vfio_id=$(lspci -nns ${d##*/} | perl -anE '$F[0] =~ /^[0-9a-f:.]+$/i && say $F[8]')
        vfio_id=${vfio_id#?};
        vfio_id=$(echo $vfio_id | cut -f1 -d":")
        local pci_id=$(get_device_id ${serial_no})
        if [ -z $pci_id ]; then
          continue;
          
        echo "$serial_no" > /sys/bus/pci/drivers/vfio-pci/unbind
        # FIXME: HOW DO we bind all the drivers correctly ? echo "$pci_id" > /sys/bus/pci/devices/"$serial_no"/driver/bind
      fi
    done
  fi
done
}

unload_vifio_modules() {
modprobe -r vfio_pci
modprobe -r vfio_iommu_type1
modprobe -r vfio
}

unbind_virtio_devices() {
local virtio_device_available=0
for g in $CACHE; do
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

  local read_link=$(readlink /sys/bus/pci/devices/"${g}"/driver)
  echo "read_link" $read_link "${g}"
  local current_driver=$(basename $read_link)
  if [[ $current_driver == "vfio-pci" ]]; then
    virtio_device_available=$((virtio_device_available+1))
    echo "$virtio_device_available) PCI ID: $PCI_ID Device Type: $DEVICE_TYPE Vendor: $vendor"
    echo "The following devices have been assigned to VM and will be detached from VM now."
    echo "Press Y followed by [ENTER] to make these devices available for rest of the system:"
    read option
    if [ "$option" != "Y" ] && [ "$option" != "y" ]; then
      echo "Skipping this device..."
      continue
    fi
  
    IOMMU_GROUP=$(find_iommu_group ${g})
    unbind_iommu_group $IOMMU_GROUP
  fi
done
}

bind_vifio_devices() {
local DEVICE_NO=0
echo "Supported devices on the platform:"
for g in $CACHE; do
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
  
  DEVICE_NO=$((DEVICE_NO+1))
  echo "$DEVICE_NO) PCI ID: $PCI_ID Device Type: $DEVICE_TYPE Vendor: $vendor Used by Host: $is_busy"
done;

if [ $DEVICE_NO == 0 ] || [ $DEVICE_NO == 1 ]; then
  echo "$DEVICE_NO GPU Device are available on the system. Minimum two GPU's are needed to support GPU Pass through for VM."
  exit 0
fi

echo "Please choose the device to be used by CrosVM:"
echo "Choose between [1-$DEVICE_NO] followed by [ENTER] to enable this option:"
read option
TEMP_DEVICE_NO=0
for g in $CACHE; do
  vendor=$(get_vendor ${g})
  if [ $vendor != "Intel" ]; then
    continue;
  fi
  TEMP_DEVICE_NO=$((TEMP_DEVICE_NO+1))
  
  if [ $TEMP_DEVICE_NO != $option ]; then
    continue;
  else
    echo "Chosen option:" $option
    PCI_ID=$(get_device_id ${g})
    DEVICE_TYPE=$(is_discrete $PCI_ID)
    is_busy=$(is_bound ${g})
    load_vifio_modules
    IOMMU_GROUP=$(find_iommu_group ${g})
    bind_iommu_group $IOMMU_GROUP
  fi
done
}

if [ $BIND_DEVICE == "unbind" ]; then
unbind_virtio_devices
else 
bind_vifio_devices
fi

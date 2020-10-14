#! /bin/bash

BIND_DEVICE=${1}
OPTION=${2}

CACHE=$(lspci -v | perl -anE '/VGA/i && $F[0] =~ /^[0-9a-f:.]+$/i && say $F[0]')

is_discrete() {
DEVICE_ID=${1}
if [ $DEVICE_ID == "4905" ] || [ $DEVICE_ID == "4908" ] || [ $DEVICE_ID == "4907" ] || [ $DEVICE_ID == "4906" ]; then
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
      echo "The following devices share the same IOMMU group and will be passed through to VM."
      for d in $g/devices/*; do
        echo -e "\t$(lspci -nns ${d##*/})"
        total_devices=$((total_devices+1))
      done;
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
        fi
          
        echo -e "Hiding \t$(lspci -nns ${d##*/})"
        echo "$vfio_id" "$pci_id" > /sys/bus/pci/drivers/vfio-pci/new_id
        echo "vfio-pci" > /sys/bus/pci/devices/"$serial_no"/driver_override
        echo "$serial_no" > /sys/bus/pci/drivers/vfio-pci/bind
        break;
      fi
    done
    break;
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
        if [[ $current_driver != "vfio-pci" ]]; then
          continue;
        fi
        
        local vfio_id=$(lspci -nns ${d##*/} | perl -anE '$F[0] =~ /^[0-9a-f:.]+$/i && say $F[8]')
        vfio_id=${vfio_id#?};
        vfio_id=$(echo $vfio_id | cut -f1 -d":")
        local pci_id=$(get_device_id ${serial_no})
        if [ -z $pci_id ]; then
          continue;
        fi
          
        echo "$serial_no" >> /sys/bus/pci/drivers/vfio-pci/unbind
        echo "$vfio_id" "$pci_id" >> /sys/bus/pci/drivers/vfio-pci/remove_id
        echo > /sys/bus/pci/devices/"$serial_no"/driver_override
      fi
    done
  fi
done
}

unbind_virtio_devices() {
IOMMU_GROUP=$(find_iommu_group $OPTION)
unbind_iommu_group $IOMMU_GROUP
}

bind_vifio_devices() {
TEMP_DEVICE_NO=0
for g in $CACHE; do
  vendor=$(get_vendor ${g})
  if [ $vendor != "Intel" ]; then
    continue;
  fi
  TEMP_DEVICE_NO=$((TEMP_DEVICE_NO+1))
  
  if [ $TEMP_DEVICE_NO != $OPTION ]; then
    continue;
  else
    PCI_ID=$(get_device_id ${g})
    DEVICE_TYPE=$(is_discrete $PCI_ID)
    is_busy=$(is_bound ${g})
    IOMMU_GROUP=$(find_iommu_group ${g})
    bind_iommu_group $IOMMU_GROUP
    SERIALNO=$(lspci -nns ${d##*/} | perl -anE '$F[0] =~ /^[0-9a-f:.]+$/i && say $F[0]')
    echo $SERIALNO
    break;
  fi
done
}

if [ $BIND_DEVICE == "unbind" ]; then
unbind_virtio_devices
else 
bind_vifio_devices 
fi


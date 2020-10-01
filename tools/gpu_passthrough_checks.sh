#! /bin/bash

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

# Check intel_iommu=on is set as kernel command line option.
if cat /proc/cmdline |
  grep "intel_iommu=on"
then
  echo "intel iommu support is enabled on the system"
else
  echo "GPU passthrough to VM cannot be enabled as intel_iommu=on option is not enabled on the system."
  echo "Press Y followed by [ENTER] to enable this option:"

  read option
  if [ "$option" == "Y" ] || [ "$option" == "y" ]; then
    mkdir -p /etc/default/grub.d
    cp $PWD/tools/crosvm_boot_options.cfg /etc/default/grub.d/
    if [ -e /boot/efi/EFI/ubuntu ]; then
      grub-install --efi-directory=/boot/efi
    fi
    update-grub  
    echo "Please reboot your system for the changes to take effect."
    exit 0
  else
    echo "The system cannot support GPU Passthrough without enabling IOMMU support."
    exit 1
  fi
fi
  
# Check if IOMMU folder is present and not empty.
if [ "$(ls -A /sys/kernel/iommu_groups/)" ]; then
  if [ "$(find /sys | grep dmar)" ]; then
    echo "IOMMU support is enabled and GPU Pass through can be supported on this platform."
  else
    echo "GPU passthrough to VM cannot be enabled. Please make sure intel_iommu and dmar support are enabled."
    exit 1
  fi

  echo "All available devices and IOMMU groups------------"
  shopt -s nullglob
  for g in /sys/kernel/iommu_groups/*; do
    echo "IOMMU Group ${g##*/}:"
    for d in $g/devices/*; do
        echo -e "\t$(lspci -nns ${d##*/})"
    done;
  done;
  echo "-----------------------------------------------"
fi



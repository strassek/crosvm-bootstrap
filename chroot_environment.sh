#! /bin/bash

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

PWD=$PWD
if bash scripts/common_checks_internal.sh; then
  echo “Configuring chroot environment...”
else
  echo “Failure, exit status: $?”
  exit 1
fi

if bash build/output/scripts/mount.sh
then
  echo "Mounted all directories. Entering Chroot...."
else
  exit
fi

sudo chroot $MOUNT_POINT su -

echo "unmounting /proc /dev/shm /dev/pts"
if bash build/output/scripts/unmount.sh then
  echo "unmounted all directories...."
else
  echo "Failed to unmount..."
fi


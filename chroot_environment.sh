#! /bin/bash

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

MOUNT_POINT=${1:-"mount"}
LOCAL_DIRECTORY_PREFIX=$PWD/build

PWD=$PWD
if bash scripts/common_checks_internal.sh --chroot; then
  echo “Configuring chroot environment...”
else
  echo “Failure, exit status: $?”
  exit 1
fi

if bash build/output/scripts/mount_internal.sh "--true" "--true" "--true" $MOUNT_POINT
then
  echo "Mounted all directories. Entering Chroot...."
else
  exit
fi

sudo chroot  $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT su -

echo "unmounting /proc /dev/shm /dev/pts"
if bash build/output/scripts/unmount_internal.sh "--true" "--true" "--true" $MOUNT_POINT
then
  echo "unmounted all directories...."
else
  echo "Failed to unmount..."
fi


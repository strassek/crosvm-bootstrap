#! /bin/bash

###################################################################
#Script to setup chroot environment for development
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

CH_COMPONENT_TARGET=${1:-"host"}
CH_LOCAL_DIRECTORY_PREFIX=$PWD/build
CH_LOCAL_SOURCE_DIR=$PWD/source

PWD=$PWD

###############################################################################
##main()
###############################################################################
if [[ "$CH_COMPONENT_TARGET" != "host" ]] && [[ "$CH_COMPONENT_TARGET" != "guest" ]] && [[ "$CH_COMPONENT_TARGET" != "game-fast" ]]; then
	echo "Invalid Component Target."
	exit 1
fi

if bash source $CH_LOCAL_SCRIPTS_DIR/common/handle_mount_umount.sh 'mount' $CH_LOCAL_DIRECTORY_PREFIX $CH_COMPONENT_TARGET $CH_LOCAL_SOURCE_DIR
then
  echo "Mounted all directories. Entering Chroot...."
else
  exit
fi

sudo chroot  $ROOTFS_COMMON_MOUNT_DIR su -

if bash source $CH_LOCAL_SCRIPTS_DIR/common/handle_mount_umount.sh 'unmount' $CH_LOCAL_DIRECTORY_PREFIX $CH_COMPONENT_TARGET $CH_LOCAL_SOURCE_DIR
then
  echo "unmounted all directories...."
else
  echo "Failed to unmount..."
fi


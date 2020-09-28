#! /bin/bash

# user.sh
# Set up user account for the VM.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

UNAME=${1:-"test"}
CHANNEL=${2:-"stable"}
BUILD_TARGET=${3:-"release"}

if [ ! -e /home/$UNAME/ ]; then
  echo "Invalid User. Please run add_user first."
fi

if [ $CHANNEL == "stable" ] && [ $BUILD_TARGET == "release" ]; then
  cp /config/stable_release.env /home/$UNAME/.bash_env_settings
fi

if [ $CHANNEL == "stable" ] && [ $BUILD_TARGET == "debug" ]; then
  cp /config/stable_debug.env /home/$UNAME/.bash_env_settings
fi

if [ $CHANNEL == "dev" ] && [ $BUILD_TARGET == "release" ]; then
  cp /config/dev_release.env /home/$UNAME/.bash_env_settings
fi

if [ $CHANNEL == "dev" ] && [ $BUILD_TARGET == "debug" ]; then
  cp /config/dev_debug.env /home/$UNAME/.bash_env_settings
fi

#! /bin/bash

# package-builder.sh
# Builds all needed drivers, cros_vm and other needed packages.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

FORCE=${1:-""}
CHANNEL=${2:-"--stable"}

PWD_DIR=$PWD
mkdir -p $PWD_DIR/source
cd $PWD_DIR/source
mkdir -p $PWD_DIR/source/env
# Repo initialization and cloning all needed Libraries.
if [ ! -f "$PWD_DIR/source/env/python" ]; then
ln -s /usr/bin/python3 $PWD_DIR/source/env/python
fi

export PATH=$PATH:$PWD_DIR/source/env/

if [ ! -d "depot_tools" ]; then
  echo "Cloning Depot Tools."
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
  git config --global color.ui false
else
  echo "Updating Depot Tools."
  git pull
fi

cd depot_tools/
export PATH=$PWD:$PATH
LOCAL_SYNC_PARAM=""

if [[ "$FORCE" == "--force" ]]; then
  LOCAL_SYNC_PARAM='--force-sync'
fi

if [ $CHANNEL == "--stable" ] || [ $CHANNEL == "--all" ]; then
  cd $PWD_DIR/source
  mkdir -p stable
  cd stable
  repo init -u  https://github.com/kalyankondapally/manifest.git -m dev.xml
  repo sync $LOCAL_SYNC_PARAM
fi

if [ $CHANNEL == "--dev" ] || [ $CHANNEL == "--all" ]; then
  cd $PWD_DIR/source
  mkdir -p dev
  cd dev
  repo init -u  https://github.com/kalyankondapally/manifest.git -m dev.xml
  repo sync $LOCAL_SYNC_PARAM
fi

if [[ -e "internal_sync_code.sh" ]]
  source internal_sync_code.sh
fi

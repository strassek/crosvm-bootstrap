#! /bin/bash

# package-builder.sh
# Builds all needed drivers, cros_vm and other needed packages.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

PWD_DIR=$PWD
mkdir -p $PWD_DIR/source
cd $PWD_DIR/source
# Repo initialization and cloning all needed Libraries.
#if [ ! -f "/usr/bin/python" ]; then
#ln -s /usr/bin/python3 /usr/bin/python # same as python-is-python3
#fi

if [ ! -d "depot_tools" ]; then
  echo "Cloning Depot Tools."
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
#  git config --global color.ui false
else
  echo "Updating Depot Tools."
  git pull
fi

cd depot_tools/
export PATH=$PWD:$PATH

cd $PWD_DIR/source
mkdir -p stable
cd stable
repo init -u  https://github.com/kalyankondapally/manifest.git -m dev.xml
repo sync

cd $PWD_DIR/source
mkdir -p dev
cd dev
repo init -u  https://github.com/kalyankondapally/manifest.git -m dev.xml
repo sync

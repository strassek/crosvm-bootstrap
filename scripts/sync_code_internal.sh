#! /bin/bash

# package-builder.sh
# Builds all needed drivers, cros_vm and other needed packages.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

cd /build

# Repo initialization and cloning all needed Libraries.
if [ ! -f "/usr/bin/python" ]; then
ln -s /usr/bin/python3 /usr/bin/python
fi

if [ ! -d "/build/depot_tools" ]; then
  echo "Cloning Depot Tools."
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
  git config --global color.ui false
else
  echo "Updating Depot Tools."
  cd /build/depot_tools/
  git pull
fi

export PATH=/build/depot_tools:$PATH

mkdir -p /build/stable
cd /build/stable
repo init -u  https://github.com/kalyankondapally/manifest.git -m dev.xml
repo sync

mkdir -p /build/dev
cd /build/dev
repo init -u  https://github.com/kalyankondapally/manifest.git -m dev.xml
repo sync

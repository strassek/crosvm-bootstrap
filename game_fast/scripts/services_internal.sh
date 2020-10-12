#! /bin/bash

# services_internal.sh
# Enable needed services for Game Fast.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

echo root:test0000 | chpasswd

echo "127.0.1.1  game-fast" >> /etc/hosts

ln -s /intel/bin/app-launcher.sh /intel/bin/launch
ln -s /intel/bin/app-launcher-x.sh /intel/bin/launch-x
ln -s /intel/bin/headless.sh /intel/bin/launch-h

echo "Done configuring the needed services and groups..."

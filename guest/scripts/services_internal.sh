#! /bin/bash

# services_internal.sh
# Enable needed services in guest side.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

echo "Enabling sommelier-stable@0.service"
if [ ! -e "/usr/lib/systemd/user/sommelier-stable@.service" ]; then
  echo "Unable to find sommelier-stable@.service file"
  exit 1
fi

systemctl --user enable sommelier-stable@0.service

echo "Enabling sommelier@1.service"
systemctl --user enable sommelier-stable@1.service

echo "Enabling sommelier-stable-x@0.service"
if [ ! -e "/usr/lib/systemd/user/sommelier-stable-x@.service" ]; then
  echo "Unable to find sommelier-stable-x@.service file"
  exit 1
fi

systemctl --user enable sommelier-stable-x@0.service
echo "Enabling sommelier-x@1.service"
systemctl --user enable sommelier-stable-x@1.service

echo root:test0000 | chpasswd

mkdir -p /etc/sudoers.d

echo "127.0.1.1  gaming" >> /etc/hosts

ln -s /intel/bin/app-launcher.sh /intel/bin/launch
ln -s /intel/bin/app-launcher-x.sh /intel/bin/launch-x

echo "Done configuring the needed services and groups..."

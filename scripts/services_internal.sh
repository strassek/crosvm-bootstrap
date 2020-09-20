#! /bin/bash

# services.sh
# Enable needed services.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

USER=$1

echo "Enabling sommelier-stable@0.service" $USER
if [ ! -e "/usr/lib/systemd/$USER/sommelier-stable@.service" ]; then
  echo "Unable to find sommelier-stable@.service file"
  exit 1
fi

sudo -u $USER systemctl --user enable sommelier-stable@0.service

echo "Enabling sommelier@1.service"
sudo -u $USER systemctl --user enable sommelier-stable@1.service

echo "Enabling sommelier-stable-x@0.service"
if [ ! -e "/usr/lib/systemd/$USER/sommelier-stable-x@.service" ]; then
  echo "Unable to find sommelier-stable-x@.service file"
  exit 1
fi
sudo -u $USER systemctl --user enable sommelier-stable-x@0.service
echo "Enabling sommelier-x@1.service"
sudo -u $USER systemctl --user enable sommelier-stable-x@1.service

sudo loginctl enable-linger $USER

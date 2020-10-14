#! /bin/bash

# services_internal.sh
# Enable needed services for Game Fast.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

echo "services internal 2"

sudo ln -s /intel/bin/app-launcher.sh /intel/bin/launch
sudo ln -s /intel/bin/app-launcher-x.sh /intel/bin/launch-x
sudo ln -s /intel/bin/headless.sh /intel/bin/launch-h

sudo mkdir -p /etc/xdg/xdg-fast-game
sudo mkdir -p /usr/share/fast-game-wayland

if [ -e /etc/skel/ ]; then
  sudo cp -RvT /etc/skel/ /home/$USER/
fi

mkdir /home/$USER/.config
mv /home/$USER/weston.ini /home/$USER/.config/

if [[ ! -e /usr/share/X11/xkb/rules/evdev ]]; then
  sudo mkdir -p /usr/share/X11/xkb/rules/evdev
  sudo ln -s /opt/stable/release/x86_64/share/X11/xkb/rules /usr/share/X11/xkb/rules/evdev
fi

if [[ ! -e /usr/bin/xkbcomp ]]; then
  sudo mkdir -p /usr/bin/xkbcomp
  sudo ln -s /opt/stable/release/x86_64/bin/ /usr/bin/xkbcomp
fi

if [[ ! -e /run/user/${UID} ]]; then
  sudo mkdir -p /run/user/${UID}
fi

sudo chown -R $USER:$USER /run/user/${UID}

if [[ ! -e /run/user/${UID}/.Xauthority ]]; then
  touch /run/user/$UID/.Xauthority
fi

sudo chown -R $USER:$USER /home/$USER/..
ls -all /home/$USER
ls -all /run/user/${UID}


echo "Done configuring the needed services and groups..."

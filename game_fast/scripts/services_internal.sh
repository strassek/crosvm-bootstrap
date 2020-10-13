#! /bin/bash

# services_internal.sh
# Enable needed services for Game Fast.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

LOCAL_USER=test
LOCAL_UID=1000

echo "services internal 2"

echo root:test0000 | chpasswd

echo "127.0.1.1  game-fast" >> /etc/hosts

ln -s /intel/bin/app-launcher.sh /intel/bin/launch
ln -s /intel/bin/app-launcher-x.sh /intel/bin/launch-x
ln -s /intel/bin/headless.sh /intel/bin/launch-h

mkdir -p /etc/xdg/xdg-fast-game
mkdir -p /usr/share/fast-game-wayland

if [ -e /etc/skel/ ]; then
  sudo -u $LOCAL_USER cp -RvT /etc/skel/ /home/$LOCAL_USER/
fi

sudo -u $LOCAL_USER mkdir /home/$LOCAL_USER/.config
sudo -u $LOCAL_USER mv /home/$LOCAL_USER/weston.ini /home/$LOCAL_USER/.config

sudo chown -R $LOCAL_USER:$LOCAL_USER /home/$LOCAL_USER/.config

if [[ ! -e /usr/share/X11/xkb/rules/evdev ]]; then
  mkdir -p /usr/share/X11/xkb/rules/evdev
  ln -s /opt/stable/release/x86_64/share/X11/xkb/rules /usr/share/X11/xkb/rules/evdev
fi

if [[ ! -e /usr/bin/xkbcomp ]]; then
  mkdir -p /usr/bin/xkbcomp
  ln -s /opt/stable/release/x86_64/bin/ /usr/bin/xkbcomp
fi

if [[ ! -e /run/user/${LOCAL_UID} ]]; then
  mkdir -p /run/user/${LOCAL_UID}
fi

if [[ ! -e /run/user/${LOCAL_UID}/.Xauthority ]]; then
  touch /run/user/$LOCAL_UID/.Xauthority
fi

chown -R $LOCAL_USER:$LOCAL_USER /run/user/${LOCAL_UID}

sudo chown -R $LOCAL_USER:$LOCAL_USER /home/$LOCAL_USER/..
ls -all /home/$LOCAL_USER
ls -all /run/user/${LOCAL_UID}


echo "Done configuring the needed services and groups..."

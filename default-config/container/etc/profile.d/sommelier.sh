#! /bin/bash

# # Launch Sommelier Deamon

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

LOCAL_USER=$(whoami)
cp /home/$LOCAL_USER/stable_release.env /home/$LOCAL_USER/.bash_env_settings
source /home/$LOCAL_USER/.bash_env_settings

export SOMMELIER_SCALE=1.0
export SOMMELIER_GLAMOR=1
export SOMMELIER_DRM_DEVICE=/dev/dri/renderD128

export XDG_SESSION_TYPE=wayland
export XDG_CONFIG_DIRS=/etc/xdg/xdg-fast-game:/etc/xdg
export DESKTOP_SESSION=fast-game-wayland
export XDG_SESSION_DESKTOP=fast-game-wayland
export XAUTHORITY=/run/user/${UID}/.Xauthority
export XDG_RUNTIME_DIR=/run/user/${UID}
export XDG_DATA_DIRS=/usr/share/fast-game-wayland:/usr/local/share/:/usr/share/
export GDMSESSION=fast-game-wayland
export DISPLAY=:0
export GNOME_SETUP_DISPLAY=:1
export LESSOPEN=| /usr/bin/lesspipe %s
export QT_QPA_PLATFORM=wayland
export GDK_BACKEND=wayland

sommelier --glamor --drm-device=/dev/dri/renderD128 --master --display=wayland-0 --socket=wayland-1  --no-exit-with-child &

echo "Launched Sommelier."

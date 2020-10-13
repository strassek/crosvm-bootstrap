#! /bin/bash

# sommelier-x.sh
# Launch Sommelier-x Deamon

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

LOCAL_USER=$(whoami)
cp /home/$LOCAL_USER/stable_release.env /home/$LOCAL_USER/.bash_env_settings
source /home/$LOCAL_USER/.bash_env_settings

export ENABLE_NATIVE_GPU=1

export DISPLAY_VAR=DISPLAY
export XCURSOR_SIZE_VAR=XCURSOR_SIZE
export SOMMELIER_SCALE=1.0
export SOMMELIER_GLAMOR=1
export SOMMELIER_DRM_DEVICE=/dev/dri/renderD128

export SOMMELIER_XFONT_PATH=/usr/share/fonts/X11/misc,\
/usr/share/fonts/X11/cyrillic,\
/usr/share/fonts/X11/100dpi/:unscaled,\
/usr/share/fonts/X11/75dpi/:unscaled,\
/usr/share/fonts/X11/Type1,\
/usr/share/fonts/X11/100dpi,\
/usr/share/fonts/X11/75dpi,

export XDG_SESSION_TYPE=x11
export XDG_CONFIG_DIRS=/etc/xdg/xdg-fast-game:/etc/xdg
export DESKTOP_SESSION=fast-game-x11
export XDG_SESSION_DESKTOP=fast-game-x11
export XAUTHORITY=/run/user/${UID}/.Xauthority
export XDG_RUNTIME_DIR=/run/user/${UID}
export XDG_DATA_DIRS=/usr/share/fast-game-x11:/usr/local/share/:/usr/share/
export GDMSESSION=fast-game-x11
export DISPLAY=:0
export GNOME_SETUP_DISPLAY=:1
export LESSOPEN=| /usr/bin/lesspipe %s
export GDK_BACKEND=x11

sommelier --glamor --drm-device=$SOMMELIER_DRM_DEVICE --master --no-exit-with-child --xwayland-path=$WLD_64/bin/Xwayland --xwayland-gl-driver-path=$WLD_64/lib/x86_64-linux-gnu/dri/ &

echo "Launched Sommelier-X"


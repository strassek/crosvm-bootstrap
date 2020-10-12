#! /bin/bash

# sommelier-x.sh
# Launch Sommelier-x Deamon

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

LOCAL_USER=$(whoami)

sudo chown -R $LOCAL_USER:$LOCAL_USER /home/$LOCAL_USER/..
cp /intel/config/stable_release.env /home/$LOCAL_USER/.bash_env_settings
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

touch ${HOME}/.Xauthority

if test -z "${XDG_RUNTIME_DIR}"; then
  export XDG_RUNTIME_DIR=/tmp/${UID}-runtime-dir
  if ! test -d "${XDG_RUNTIME_DIR}"; then
    mkdir "${XDG_RUNTIME_DIR}"
    chmod 0700 "${XDG_RUNTIME_DIR}"
  fi
fi

sommelier --glamor --drm-device=/dev/dri/renderD128 --master --x-display=0 --no-exit-with-child --x-auth=${HOME}/.Xauthority --xwayland-path=$WLD_64/bin/Xwayland --xwayland-gl-driver-path=$WLD_64/lib/x86_64-linux-gnu/dri/ &

/bin/sh -c "touch ${HOME}/.Xauthority; xauth -f ${HOME}/.Xauthority add game-fast:0 . $(xxd -l 16 -p /dev/urandom);"

export ${DISPLAY_VAR}=$${DISPLAY}
export ${XCURSOR_SIZE_VAR}=$${XCURSOR_SIZE}

if command -v xdpyinfo >/dev/null && command -v xrdb >/dev/null; then
  DPI=$(xdpyinfo | sed -n -E "/dots per inch/{s|^.* ([0-9]+)x.*$|\1|g; p}")
  echo "Xft.dpi: ${DPI}" | xrdb -merge
fi

if command -v xsetroot >/dev/null; then
  xsetroot -cursor_name left_ptr
fi

echo "Launched Sommelier-X"


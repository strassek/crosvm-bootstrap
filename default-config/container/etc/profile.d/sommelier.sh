#! /bin/bash

# # Launch Sommelier Deamon

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

LOCAL_USER=$(whoami)

sudo chown -R $LOCAL_USER:$LOCAL_USER /home/$LOCAL_USER/..
cp /intel/config/.bashrc /home/$LOCAL_USER/
cp /intel/config/stable_release.env /home/$LOCAL_USER/.bash_env_settings
source /home/$LOCAL_USER/.bash_env_settings

if test -z "${XDG_RUNTIME_DIR}"; then
  export XDG_RUNTIME_DIR=/tmp/${UID}-runtime-dir
  if ! test -d "${XDG_RUNTIME_DIR}"; then
    mkdir "${XDG_RUNTIME_DIR}"
    chmod 0700 "${XDG_RUNTIME_DIR}"
  fi
fi

export ENABLE_NATIVE_GPU=1
export SOMMELIER_GLAMOR=1
export SOMMELIER_DRM_DEVICE=/dev/dri/renderD128
export WAYLAND_DISPLAY_VAR=WAYLAND_DISPLAY

sommelier --glamor --drm-device=/dev/dri/renderD128 --master --socket=wayland-1 --no-exit-with-child &
export ${WAYLAND_DISPLAY_VAR}=$${WAYLAND_DISPLAY}

echo "Launched Sommelier"

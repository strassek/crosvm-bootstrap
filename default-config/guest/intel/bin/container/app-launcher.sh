#! /bin/bash

TARGET=$1
DEBUG=${2:-"--false"}
CHANNEL=${3:-"--stable"}
BUILD_TARGET=${4:-"--release"}
LOCAL_USER=$(whoami)
LOCAL_ENV_PATH=/home/$LOCAL_USER/.env_conf

if [[ "$CHANNEL" == "--stable" ]] && [[ "$BUILD_TARGET" == "--release" ]]; then
  cp $LOCAL_ENV_PATH/stable_release.env /home/$LOCAL_USER/.bash_env_settings
fi

if [[ "$CHANNEL" == "--stable" ]] && [[ "$BUILD_TARGET" == "--debug" ]]; then
  cp $LOCAL_ENV_PATH/stable_debug.env /home/$LOCAL_USER/.bash_env_settings
fi

if [[ "$CHANNEL" == "--dev" ]] && [[ "$BUILD_TARGET" == "--release" ]]; then
  cp $LOCAL_ENV_PATH/dev_release.env /home/$LOCAL_USER/.bash_env_settings
fi

if [[ "$CHANNEL" == "--dev" ]] && [[ "$BUILD_TARGET" == "--debug" ]]; then
  cp $LOCAL_ENV_PATH/dev_debug.env /home/$LOCAL_USER/.bash_env_settings
fi

source /home/$LOCAL_USER/.bash_env_settings

if [[ "$DEBUG" == "--true" ]]; then
  export MESA_DEBUG=1
  export EGL_LOG_LEVEL=debug
  export LIBGL_DEBUG=verbose
  export WAYLAND_DEBUG=1
fi

export SOMMELIER_SCALE=1.0
export SOMMELIER_GLAMOR=1
export SOMMELIER_DRM_DEVICE=/dev/dri/renderD128
export SOMMELIER_VIRTWL_DEVICE=/dev/wl0

sommelier --glamor --drm-device=/dev/dri/renderD128 $1

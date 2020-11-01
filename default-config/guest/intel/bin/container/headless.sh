#! /bin/bash

TARGET=$1
DEBUG=${2:-"--false"}
CHANNEL=${3:-"--stable"}
BUILD_TARGET=${4:-"--release"}
LOCAL_USER=$(whoami)

if [[ "$CHANNEL" == "--stable" ]] && [[ "$BUILD_TARGET" == "--release" ]]; then
  cp /home/$LOCAL_USER/stable_release.env /home/$LOCAL_USER/.bash_env_settings
fi

if [[ "$CHANNEL" == "--stable" ]] && [[ "$BUILD_TARGET" == "--debug" ]]; then
  cp /home/$LOCAL_USER/stable_debug.env /home/$LOCAL_USER/.bash_env_settings
fi

if [[ "$CHANNEL" == "--dev" ]] && [[ "$BUILD_TARGET" == "--release" ]]; then
  cp /home/$LOCAL_USER/dev_release.env /home/$LOCAL_USER/.bash_env_settings
fi

if [[ "$CHANNEL" == "--dev" ]] && [[ "$BUILD_TARGET" == "--debug" ]]; then
  cp /home/$LOCAL_USER/dev_debug.env /home/$LOCAL_USER/.bash_env_settings
fi

source /home/$LOCAL_USER/.bash_aliases

if [[ "$DEBUG" == "--true" ]]; then
  export MESA_DEBUG=1
  export EGL_LOG_LEVEL=debug
  export LIBGL_DEBUG=verbose
  export WAYLAND_DEBUG=1
fi

"$@"

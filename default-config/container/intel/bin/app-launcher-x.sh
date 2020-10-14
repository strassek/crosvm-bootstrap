#! /bin/bash

TARGET=$1
ENABLE_USERPTR=${2:-"--false"}
ENABLE_NATIVE_GPU=${3:-"--false"}
DEBUG=${4:-"--false"}
CHANNEL=${5:-"--stable"}
BUILD_TARGET=${6:-"--release"}
LOCAL_USER=$(whoami)

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin

cp /home/$LOCAL_USER/stable_release.env /home/$LOCAL_USER/.bash_env_settings
source /home/$LOCAL_USER/.bash_env_settings

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

source /home/$LOCAL_USER/.bash_env_settings

if [[ "$DEBUG" == "--true" ]]; then
  export MESA_DEBUG=1
  export EGL_LOG_LEVEL=debug
  export LIBGL_DEBUG=verbose
fi

if [[ "$ENABLE_USERPTR" == "--true" ]]; then
  export ENABLE_USERPTR=1
fi

if [[ "$ENABLE_NATIVE_GPU" == "--true" ]]; then
  export ENABLE_NATIVE_GPU=1
fi

export SOMMELIER_SCALE=1.0
export SOMMELIER_GLAMOR=1
export SOMMELIER_DRM_DEVICE=/dev/dri/renderD128
export SOMMELIER_VIRTWL_DEVICE=/dev/wl0
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
export GDK_BACKEND=wayland
export XKB_BINDIR=/usr/bin

if [[ "$TARGET" == "steam" ]]; then
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib32:/usr/lib:/usr/lib/x86_64-linux-gnu
  export PATH=$PATH:/usr/lib32:/usr/lib:/usr/lib/x86_64-linux-gnu
  STEAM_RUNTIME=0 sommelier --glamor --drm-device=/dev/dri/renderD128 -X $1
else
  sommelier --glamor --drm-device=/dev/dri/renderD128 -X $1
fi

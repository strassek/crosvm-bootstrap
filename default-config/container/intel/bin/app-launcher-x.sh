#! /bin/bash

TARGET=$1
ENABLE_USERPTR=${2:-"--false"}
DEBUG=${3:-"--false"}
CHANNEL=${4:-"--stable"}
BUILD_TARGET=${5:-"--release"}
LOCAL_USER=$(whoami)

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
export ENABLE_NATIVE_GPU=1

if [[ "$DEBUG" == "--true" ]]; then
  export MESA_DEBUG=1
  export EGL_LOG_LEVEL=debug
  export LIBGL_DEBUG=verbose
fi

if [[ "$ENABLE_USERPTR" == "--true" ]]; then
  export ENABLE_USERPTR=1
fi

if [[ "$TARGET" == "steam" ]]; then
  LD_PRELOAD=$WLD/lib/libdrm.so
  LD_PRELOAD=$WLD/lib/libdrm_intel.so
  LD_PRELOAD=$WLD/lib/dri/iris_dri.so
  LD_PRELOAD=$WLD/lib/x86_64-linux-gnu/libglapi.so
  LD_PRELOAD=$WLD/lib/x86_64-linux-gnu/libGLESv2.so
  LD_PRELOAD=$WLD/lib/x86_64-linux-gnu/libGLESv1_CM.so
  LD_PRELOAD=$WLD/lib/x86_64-linux-gnu/libGL.so
  LD_PRELOAD=$WLD/lib/x86_64-linux-gnu/libEGL.so
  LD_PRELOAD=$WLD/lib/x86_64-linux-gnu/libvulkan_intel.so
  LD_PRELOAD=$WLD/lib/x86_64-linux-gnu/libepoxy.so
  LD_PRELOAD=$WLD/lib/x86_64-linux-gnu/libgbm.so
  LD_PRELOAD=$WLD/lib/libxcb-glx.so
  LD_PRELOAD=$WLD/lib/libxcb-dri3.so
  LD_PRELOAD=$WLD/lib/libxcb-dri2.so
  LD_PRELOAD=$WLD/lib/libX11.so
fi

LD_PRELOAD=$WLD_64/lib/x86_64-linux-gnu/libdrm.so
LD_PRELOAD=$WLD_64/lib/x86_64-linux-gnu/libdrm_intel.so
LD_PRELOAD=$WLD_64/lib/x86_64-linux-gnu/dri/iris_dri.so
LD_PRELOAD=$WLD_64/lib/x86_64-linux-gnu/libglapi.so
LD_PRELOAD=$WLD_64/lib/x86_64-linux-gnu/libGLESv2.so
LD_PRELOAD=$WLD_64/lib/x86_64-linux-gnu/libGLESv1_CM.so
LD_PRELOAD=$WLD_64/lib/x86_64-linux-gnu/libGL.so
LD_PRELOAD=$WLD_64/lib/x86_64-linux-gnu/libEGL.so
LD_PRELOAD=$WLD_64/lib/x86_64-linux-gnu/libvulkan_intel.so
LD_PRELOAD=$WLD_64/lib/x86_64-linux-gnu/libepoxy.so
LD_PRELOAD=$WLD_64/lib/x86_64-linux-gnu/libgbm.so
LD_PRELOAD=$WLD_64/lib/x86_64-linux-gnu/libxcb-glx.so
LD_PRELOAD=$WLD_64/lib/x86_64-linux-gnu/libxcb-dri3.so
LD_PRELOAD=$WLD_64/lib/x86_64-linux-gnu/libxcb-dri2.so
LD_PRELOAD=$WLD_64/lib/x86_64-linux-gnu/libX11.so


sommelier --glamor --drm-device=/dev/dri/renderD128 -X $1

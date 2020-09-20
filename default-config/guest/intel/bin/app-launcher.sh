#! /bin/bash

TARGET=$1
WAYLAND_DISPLAY=${2:"wayland-0"}
DEBUG=${3:-"false"}
X_APP=${4:-"false"}
X_DISPLAY=${5:"0"}
CURRENT_CHANNEL=${5:-"stable"}
LOCAL_CHANNEL=stable
LOCAL_LAUNCH_TYPE=release

if [ $CURRENT_CHANNEL == "--alpha" ]; then
LOCAL_CHANNEL=alpha
fi

if [ $CURRENT_CHANNEL == "--beta" ]; then
LOCAL_CHANNEL=beta
fi

if [ $DEBUG == "--true" ]; then
LOCAL_LAUNCH_TYPE=debug
fi

# Set Lib Directory based on the channel.
BASE_DIR=/$LOCAL_CHANNEL/$LOCAL_LAUNCH_TYPE

# Export environment variables
export WLD=$BASE_DIR/x86
export WLD_64=$BASE_DIR/x86_64

if [ $DEBUG == "--true" ]; then
export MESA_DEBUG=1
export EGL_LOG_LEVEL=debug
export LIBGL_DEBUG=verbose
export WAYLAND_DEBUG=1
fi

export LIBGL_DRIVERS_PATH=$WLD_64/lib/x86_64-linux-gnu/dri:$WLD/lib/dri
export LD_LIBRARY_PATH=$WLD_64/lib/x86_64-linux-gnu:$WLD_64/lib/x86_64-linux-gnu/dri:$WLD/lib:$WLD/lib/dri
export LIBVA_DRIVERS_PATH=$WLD_64/lib/x86_64-linux-gnu:$WLD/lib
export LIBVA_DRIVER_NAME=iHD

if [ $X_APP == "--true" ]; then
  sommelier -X --xwayland-path=/bin/Xwayland --x-display=:$X_DISPLAY $1
else
  sommelier --glamor --display=$WAYLAND_DISPLAY $1
fi

#! /bin/bash

# package-builder.sh
# Builds all needed drivers, cros_vm and other needed packages.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

BUILD_TARGET=${1:-"--release"}
BUILD_TYPE=${2:-"--incremental"}
BUILD_CHANNEL=${3:-"--stable"}
LOCAL_BUILD_TARGET=release
LOCAL_CHANNEL=stable

if /scripts/host/common_build_internal.sh $BUILD_TYPE $BUILD_TARGET $BUILD_CHANNEL
then
  echo "Starting Build...."
else
  echo "Unable to setup proper build environment. Quitting..."
  exit 1
fi


if [ $BUILD_CHANNEL == "--dev" ]; then
LOCAL_CHANNEL=dev
fi

if [ $BUILD_TARGET == "--debug" ]; then
LOCAL_BUILD_TARGET=debug
fi

LOCAL_CURRENT_WLD_PATH=/opt/$LOCAL_CHANNEL/$LOCAL_BUILD_TARGET/x86_64
LOCAL_MESON_BUILD_DIR=build.$LOCAL_BUILD_TARGET.x86_64

# Export environment variables
export C_INCLUDE_PATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
export CPLUS_INCLUDE_PATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
export CPATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
export PATH="$LOCAL_CURRENT_WLD_PATH/include/:$LOCAL_CURRENT_WLD_PATH/include/libdrm/:$LOCAL_CURRENT_WLD_PATH/bin:$PATH"
export ACLOCAL_PATH=$LOCAL_CURRENT_WLD_PATH/share/aclocal
export ACLOCAL="aclocal -I $ACLOCAL_PATH"
export PKG_CONFIG_PATH=$LOCAL_CURRENT_WLD_PATH/lib/x86_64-linux-gnu/pkgconfig:$LOCAL_CURRENT_WLD_PATH/lib/pkgconfig:$LOCAL_CURRENT_WLD_PATH/share/pkgconfig:/lib/x86_64-linux-gnu/pkgconfig
export PKG_CONFIG_PATH_FOR_BUILD=$PKG_CONFIG_PATH

# Set Working Build directory based on the channel.
WORKING_DIR=/build/$LOCAL_CHANNEL/wayland

echo "Working Directory:" $WORKING_DIR
env
echo "---------------------------------"

cd /build

FORCE_CONFIGURE=0
function make_clean_asneeded() {
if [ $BUILD_TYPE == "--clean" ]; then
  if [ "$(find . | grep -i '.*[.]o' | wc -c)" != 0 ]; then
    echo "make clean called"
    make clean || true
    FORCE_CONFIGURE=1
  else
    echo "Skipped make clean as this is incremental build or project has not been configured."
  fi
fi
}

LOCAL_PER_COMPONENT_OPTIONS=""
function configure_asneeded() {
if [ $FORCE_CONFIGURE == 1 ]; then
  echo "Configuring the project"
  ./autogen.sh --prefix=$LOCAL_CURRENT_WLD_PATH $LOCAL_PER_COMPONENT_OPTIONS
  FORCE_CONFIGURE=0
  LOCAL_PER_COMPONENT_OPTIONS=""
else
  if [ "$(find . | grep -i '.*[.]o' | wc -c)" == 0 ]; then
    echo "Configuring the project"
    ./autogen.sh --prefix=$LOCAL_CURRENT_WLD_PATH $LOCAL_PER_COMPONENT_OPTIONS
    FORCE_CONFIGURE=0
    LOCAL_PER_COMPONENT_OPTIONS=""
  else
    echo "Skipped configuring the project as this is incremental build."
  fi
fi
}

function autogen_build() {
#make_clean_asneeded
#configure_asneeded
make clean || true
./autogen.sh --prefix=$LOCAL_CURRENT_WLD_PATH $LOCAL_PER_COMPONENT_OPTIONS
make install
}

function mesonclean_asneeded() {
if [[ ($BUILD_TYPE == "--clean" && -d $LOCAL_MESON_BUILD_DIR) ]]; then
  rm -rf $LOCAL_MESON_BUILD_DIR
fi
}

echo "checking " $LOCAL_CURRENT_WLD_PATH/share/aclocal
mkdir -p $LOCAL_CURRENT_WLD_PATH/share/aclocal
if [ ! -d "$LOCAL_CURRENT_WLD_PATH/share/aclocal" ]; then
  echo "Failed to create" $LOCAL_CURRENT_WLD_PATH/share/aclocal
else
  echo $LOCAL_CURRENT_WLD_PATH/share/aclocal "exists"
fi

# Build wayland
echo "Building wayland............"
cd $WORKING_DIR/wayland
LOCAL_PER_COMPONENT_OPTIONS="--disable-documentation"
autogen_build
make install

# Build wayland-protocols
echo "Building wayland-protocols............"
cd $WORKING_DIR/wayland-protocols
autogen_build
make install

# Build libxkbcommon
echo "Building libxkbcommon............"
cd $WORKING_DIR/libxkbcommon
mesonclean_asneeded
echo $PKG_CONFIG_PATH "PKG_CONFIG_PATH"
meson setup $LOCAL_MESON_BUILD_DIR -Dprefix=$LOCAL_CURRENT_WLD_PATH -Denable-x11=true -Denable-wayland=true -Denable-docs=false && ninja -C $LOCAL_MESON_BUILD_DIR install


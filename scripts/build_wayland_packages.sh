#! /bin/bash

# package-builder.sh
# Builds all needed drivers, cros_vm and other needed packages.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

BUILD_TYPE=${1:-"--release"}
CLEAN_BUILD=${2:-"--incremental"}
BUILD_CHANNEL=${3:-"--stable"}
BUILD_ARCH=${4:-"--64bit"}
LOCAL_BUILD_TYPE=release
LOCAL_CHANNEL=stable

if /build/output/scripts/common_build_internal.sh $BUILD_TYPE $CLEAN_BUILD $BUILD_CHANNEL $BUILD_ARCH
then
  echo "Starting Build...."
else
  echo "Unable to setup proper build environment. Quitting..."
  exit 1
fi


if [ $BUILD_CHANNEL == "--dev" ]; then
LOCAL_CHANNEL=dev
fi

if [ $BUILD_TYPE == "--debug" ]; then
LOCAL_BUILD_TYPE=debug
fi

LOCAL_CURRENT_WLD_PATH=/opt/$LOCAL_CHANNEL/$LOCAL_BUILD_TYPE/x86_64
LOCAL_MESON_COMPILER_OPTIONS=""
LOCAL_COMPILER_OPTIONS=""
LOCAL_MESON_BUILD_DIR=build.$LOCAL_BUILD_TYPE.x86_64
CROSS_SETTINGS=/build/meson-cross-i686-$LOCAL_CHANNEL-$LOCAL_BUILD_TYPE.ini

if [ $BUILD_ARCH == "--64bit" ]; then
  echo "64 bit build"
else
  echo "32 bit build"
  LOCAL_CURRENT_WLD_PATH=/opt/$LOCAL_CHANNEL/$LOCAL_BUILD_TYPE/x86
  LOCAL_MESON_BUILD_DIR=build.$LOCAL_BUILD_TYPE.x86
fi

# Export environment variables
export C_INCLUDE_PATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
export CPLUS_INCLUDE_PATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
export CPATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
export PATH="$PATH:$LOCAL_CURRENT_WLD_PATH/include/:$LOCAL_CURRENT_WLD_PATH/include/libdrm/:$LOCAL_CURRENT_WLD_PATH/bin"
export ACLOCAL_PATH=$LOCAL_CURRENT_WLD_PATH/share/aclocal
export ACLOCAL="aclocal -I $ACLOCAL_PATH"
export PKG_CONFIG_PATH=$LOCAL_CURRENT_WLD_PATH/lib/pkgconfig:$LOCAL_CURRENT_WLD_PATH/share/pkgconfig
export PATH="$PATH:$LOCAL_CURRENT_WLD_PATH/bin"

# Set Working Build directory based on the channel.
WORKING_DIR=/build/$LOCAL_CHANNEL/wayland

echo "Working Directory:" $WORKING_DIR

if [ $BUILD_ARCH == "--64bit" ]; then
  export PKG_CONFIG_PATH=$LOCAL_CURRENT_WLD_PATH/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH:/lib/x86_64-linux-gnu/pkgconfig

  env
  echo "---------------------------------"
else
  LOCAL_COMPILER_OPTIONS="--host=i686-linux-gnu "CFLAGS=-m32" "CXXFLAGS=-m32" "LDFLAGS=-m32" --prefix=$LOCAL_CURRENT_WLD_PATH"
  LOCAL_MESON_COMPILER_OPTIONS="--cross-file $CROSS_SETTINGS"
  # 32 bit builds
  export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/lib/i386-linux-gnu/pkgconfig:/lib/i386-linux-gnu/pkgconfig
  export PKG_CONFIG_PATH_FOR_BUILD=$PKG_CONFIG_PATH
  export CC=/usr/bin/i686-linux-gnu-gcc

  env
  echo "........................................................"
fi

cd /build

FORCE_CONFIGURE=0
function make -j0 clean_asneeded() {
if [ $CLEAN_BUILD == "--clean" ]; then
  if [ "$(find . | grep -i '.*[.]o' | wc -c)" != 0 ]; then
    echo "make -j0  clean called"
    make -j0  clean || true
    FORCE_CONFIGURE=1
  else
    echo "Skipped make -j0  clean as this is incremental build or project has not been configured."
  fi
fi
}

LOCAL_PER_COMPONENT_OPTIONS=""
function configure_asneeded() {
if [ $FORCE_CONFIGURE == 1 ]; then
  echo "Configuring the project"
  ./autogen.sh --prefix=$LOCAL_CURRENT_WLD_PATH $LOCAL_COMPILER_OPTIONS $LOCAL_PER_COMPONENT_OPTIONS
  FORCE_CONFIGURE=0
  LOCAL_PER_COMPONENT_OPTIONS=""
else
  if [ "$(find . | grep -i '.*[.]o' | wc -c)" == 0 ]; then
    echo "Configuring the project"
    ./autogen.sh --prefix=$LOCAL_CURRENT_WLD_PATH $LOCAL_COMPILER_OPTIONS $LOCAL_PER_COMPONENT_OPTIONS
    FORCE_CONFIGURE=0
    LOCAL_PER_COMPONENT_OPTIONS=""
  else
    echo "Skipped configuring the project as this is incremental build."
  fi
fi
}

function autogen_build() {
#make -j0 clean_asneeded
#configure_asneeded
make -j0  clean || true
./autogen.sh --prefix=$LOCAL_CURRENT_WLD_PATH $LOCAL_COMPILER_OPTIONS $LOCAL_PER_COMPONENT_OPTIONS
make -j0  install
}

function mesonclean_asneeded() {
if [[ ($CLEAN_BUILD == "--clean" && -d $LOCAL_MESON_BUILD_DIR) ]]; then
  rm -rf $LOCAL_MESON_BUILD_DIR
fi
}

# Create settings for cross compiling
if [ $CLEAN_BUILD == "--clean" ]; then
  if [ -f $CROSS_SETTINGS ]; then
    rm $CROSS_SETTINGS
  fi
fi

if [ ! -f $CROSS_SETTINGS ]; then
cat > $CROSS_SETTINGS <<EOF
[binaries]
c = '/usr/bin/i686-linux-gnu-gcc'
cpp = '/usr/bin/i686-linux-gnu-g++'
ar = '/usr/bin/i686-linux-gnu-gcc-ar'
strip = '/usr/bin/i686-linux-gnu-strip'
pkgconfig = '/usr/bin/i686-linux-gnu-pkg-config'
build.pkg_config_path = '/usr/bin/i686-linux-gnu-pkg-config'

[properties]
pkg_config_libdir = '$PKG_CONFIG_PATH'
c_args = ['-m32']
c_link_args = ['-m32']
cpp_args = ['-m32']
cpp_link_args = ['-m32']

[host_machine]
system = 'linux'
cpu_family = 'x86'
cpu = 'i686'
endian = 'little'
EOF
fi

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
if [ $BUILD_ARCH == "--64bit" ]; then
  LOCAL_PER_COMPONENT_OPTIONS="--disable-documentation"
else
  LOCAL_PER_COMPONENT_OPTIONS="--disable-documentation"
fi
autogen_build
make -j0  install

# Build wayland-protocols
echo "Building wayland-protocols............"
cd $WORKING_DIR/wayland-protocols
autogen_build
make -j0  install

# Build libxkbcommon
echo "Building libxkbcommon............"
cd $WORKING_DIR/libxkbcommon
mesonclean_asneeded
meson setup $LOCAL_MESON_BUILD_DIR -Dprefix=$LOCAL_CURRENT_WLD_PATH -Denable-x11=true -Denable-wayland=true -Denable-docs=false -Dscanner=false $LOCAL_MESON_COMPILER_OPTIONS && ninja -C $LOCAL_MESON_BUILD_DIR install


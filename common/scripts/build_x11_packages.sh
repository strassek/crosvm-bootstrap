#! /bin/bash

# build-x11-packages.sh
# Builds x11 packages.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

BUILD_TARGET=${1:-"--release"}
BUILD_TYPE=${2:-"--incremental"}
BUILD_CHANNEL=${3:-"--stable"}
BUILD_ARCH=${4:-"x86_64"}
LOCAL_BUILD_TARGET=release
LOCAL_CHANNEL=stable

if /scripts/common/common_build_internal.sh $BUILD_TYPE $BUILD_TARGET $BUILD_CHANNEL $BUILD_ARCH
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

# Set Working Build directory based on the channel.
WORKING_DIR=/build/$LOCAL_CHANNEL/x11

if [ $BUILD_ARCH == "i386" ]; then
  LOCAL_CURRENT_WLD_PATH=/opt/$LOCAL_CHANNEL/$LOCAL_BUILD_TARGET/x86
  LOCAL_MESON_BUILD_DIR=build.$LOCAL_BUILD_TARGET.x86
  LOCAL_COMPILER_OPTIONS="--host=i686-linux-gnu "CFLAGS=-m32" "CXXFLAGS=-m32" "LDFLAGS=-m32" --prefix=$LOCAL_CURRENT_WLD_PATH"
  CROSS_SETTINGS=meson-cross-i686-$LOCAL_CHANNEL-$LOCAL_BUILD_TARGET.ini
  LOCAL_MESON_COMPILER_OPTIONS="--cross-file $CROSS_SETTINGS"

  # Export environment variables
  export C_INCLUDE_PATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
  export CPLUS_INCLUDE_PATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
  export CPATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
  export PATH="$PATH:$LOCAL_CURRENT_WLD_PATH/include/:$LOCAL_CURRENT_WLD_PATH/include/libdrm/:$LOCAL_CURRENT_WLD_PATH/bin"
  export ACLOCAL_PATH=$LOCAL_CURRENT_WLD_PATH/share/aclocal
  export ACLOCAL="aclocal -I $ACLOCAL_PATH"
  export PKG_CONFIG_PATH=$LOCAL_CURRENT_WLD_PATH/lib/pkgconfig:$LOCAL_CURRENT_WLD_PATH/share/pkgconfig:/usr/lib/i386-linux-gnu/pkgconfig:/usr/lib/i386-linux-gnu/pkgconfig:/lib/i386-linux-gnu/pkgconfig
  export PKG_CONFIG_PATH_FOR_BUILD=$PKG_CONFIG_PATH
  export CC=/usr/bin/i686-linux-gnu-gcc
else
  LOCAL_CURRENT_WLD_PATH=/opt/$LOCAL_CHANNEL/$LOCAL_BUILD_TARGET/x86_64
  LOCAL_MESON_BUILD_DIR=build.$LOCAL_BUILD_TARGET.x86_64
  LOCAL_MESON_COMPILER_OPTIONS=""
  LOCAL_COMPILER_OPTIONS=""

  # Export environment variables
  export C_INCLUDE_PATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
  export CPLUS_INCLUDE_PATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
  export CPATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
  export PATH="$PATH:$LOCAL_CURRENT_WLD_PATH/include/:$LOCAL_CURRENT_WLD_PATH/include/libdrm/:$LOCAL_CURRENT_WLD_PATH/bin"
  export ACLOCAL_PATH=$LOCAL_CURRENT_WLD_PATH/share/aclocal
  export ACLOCAL="aclocal -I $ACLOCAL_PATH"
  export PKG_CONFIG_PATH=$LOCAL_CURRENT_WLD_PATH/lib/x86_64-linux-gnu/pkgconfig:$LOCAL_CURRENT_WLD_PATH/lib/pkgconfig:$LOCAL_CURRENT_WLD_PATH/share/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/lib/x86_64-linux-gnu/pkgconfig
fi

echo "Working Directory:" $WORKING_DIR
env
echo "---------------------------------"

if [ $BUILD_ARCH == "i386" ]; then
  # Create settings for cross compiling
  if [ $BUILD_TYPE == "--clean" ]; then
    if [ -f $CROSS_SETTINGS ]; then
      rm $CROSS_SETTINGS
    fi
  fi

generate_compiler_settings() {
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
}
else
generate_compiler_settings() {
echo "64bit build"
}
fi

cd /build

FORCE_CONFIGURE=0
function make_clean_asneeded() {
if [ $CLEAN_BUILD == "--clean" ]; then
  if [ "$(find . | grep -i '.*[.]o' | wc -c)" == 0 ]; then
    echo "make -j0  clean called"
    make clean || true
    FORCE_CONFIGURE=1
  else
    echo "Skipped make -j0  clean as this is incremental build or project has not been configured."
  fi
fi
}

function configure_asneeded() {
if [ $FORCE_CONFIGURE == 1 ]; then
  echo "Configuring the project"
  ./autogen.sh --prefix=$LOCAL_CURRENT_WLD_PATH $LOCAL_COMPILER_OPTIONS
  FORCE_CONFIGURE=0
else
  if [ "$(find . | grep -i '.*[.]o' | wc -c)" != 0 ]; then
    echo "Configuring the project"
    ./autogen.sh --prefix=$LOCAL_CURRENT_WLD_PATH $LOCAL_COMPILER_OPTIONS
    FORCE_CONFIGURE=0
  else
    echo "Skipped configuring the project as this is incremental build."
  fi
fi
}

function autogen_build() {
#make -j0 clean_asneeded
#configure_asneeded
make clean || true
./autogen.sh --prefix=$LOCAL_CURRENT_WLD_PATH $LOCAL_COMPILER_OPTIONS
make install
}

echo "checking " $LOCAL_CURRENT_WLD_PATH/share/aclocal
mkdir -p $LOCAL_CURRENT_WLD_PATH/share/aclocal
if [ ! -d "$LOCAL_CURRENT_WLD_PATH/share/aclocal" ]; then
  echo "Failed to create" $LOCAL_CURRENT_WLD_PATH/share/aclocal
else
  echo $LOCAL_CURRENT_WLD_PATH/share/aclocal "exists"
fi

# Build libpciaccess.
echo "Building libraries............"
echo "Building libpciaccess............"
cd $WORKING_DIR/libpciaccess
autogen_build

# Build pixman.
cd $WORKING_DIR/pixman
echo "Building pixman............"
autogen_build

# Build xcbproto
cd $WORKING_DIR/xcbproto
echo "Building xcbproto............"
autogen_build

# Build xorgproto
echo "Building xorgproto............"
cd $WORKING_DIR/xorgproto
if [[ ($BUILD_TYPE == "--clean" && -d $LOCAL_MESON_BUILD_DIR) ]]; then
  rm -rf $LOCAL_MESON_BUILD_DIR
fi

if [ $BUILD_ARCH == "i386" ]; then
  generate_compiler_settings
fi

meson setup $LOCAL_MESON_BUILD_DIR -Dprefix=$LOCAL_CURRENT_WLD_PATH $LOCAL_MESON_COMPILER_OPTIONS && ninja -C $LOCAL_MESON_BUILD_DIR install

# Build libxau
echo "Building libxau............"
cd $WORKING_DIR/libxau
autogen_build

# Build libxcb
cd $WORKING_DIR/libxcb
echo "Building libxcb............"
autogen_build

# Build xorg-libxtrans
cd $WORKING_DIR/libxtrans
echo "Building libxtrans............"
autogen_build

# Build xorg-libX11
cd $WORKING_DIR/libX11
echo "Building libX11............"
autogen_build

# Build libxkbfile
cd $WORKING_DIR/libxkbfile
echo "Building libxkbfile............"
autogen_build

# Build libxfont
echo "Building libxfont............"
cd $WORKING_DIR/libxfont
autogen_build

# Build libxext
echo "Building libxext............"
cd $WORKING_DIR/libxext
autogen_build

# Build libxfixes
echo "Building libxfixes............"
cd $WORKING_DIR/libxfixes
autogen_build

# Build libxdamage
echo "Building libxdamage............"
cd $WORKING_DIR/libxdamage
autogen_build

# Build libxshmfence
echo "Building libxshmfence............"
cd $WORKING_DIR/libxshmfence
autogen_build

# Build libxxf86vm
echo "Building libxxf86vm............"
cd $WORKING_DIR/libxxf86vm
autogen_build

# Build libxrender
echo "Building libxrender............"
cd $WORKING_DIR/libxrender
autogen_build

# Build libxrandr
echo "Building libxrandr............"
cd $WORKING_DIR/libxrandr
autogen_build

# Build libxxf86vm
echo "Building libxdmcp............"
cd $WORKING_DIR/libxdmcp
autogen_build

# Build font util
echo "Building util............"
cd $WORKING_DIR/util
autogen_build

# Build xkbcomp
echo "Building xkbcomp............"
cd $WORKING_DIR/xkbcomp
autogen_build

# Build xkeyboard-config
echo "Building xkeyboard-config............"
cd $WORKING_DIR/xkeyboard-config
autogen_build

# Build libXi
echo "Building libXi............"
cd $WORKING_DIR/libXi
autogen_build

# Build xtst
echo "Building xtst............"
cd $WORKING_DIR/xtst
autogen_build



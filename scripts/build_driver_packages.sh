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
LOCAL_LIBDIR=lib/x86_64-linux-gnu
LOCAL_COMPILER_OPTIONS=""
LOCAL_MESON_BUILD_DIR=build.$LOCAL_BUILD_TYPE.x86_64
CROSS_SETTINGS=/build/meson-cross-i686-$LOCAL_CHANNEL-$LOCAL_BUILD_TYPE.ini

if [ $BUILD_ARCH == "--64bit" ]; then
  echo "64 bit build"
else
  echo "32 bit build"
  LOCAL_CURRENT_WLD_PATH=/opt/$LOCAL_CHANNEL/$LOCAL_BUILD_TYPE/x86
  LOCAL_MESON_BUILD_DIR=build.$LOCAL_BUILD_TYPE.x86
  LOCAL_LIBDIR=lib
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
WORKING_DIR=/build/$LOCAL_CHANNEL/drivers

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

# Build drm
echo "Building drm............"
cd $WORKING_DIR/mesa-drm
mesonclean_asneeded

meson setup $LOCAL_MESON_BUILD_DIR -Dprefix=$LOCAL_CURRENT_WLD_PATH -Dintel=true -Dradeon=false -Damdgpu=false -Dnouveau=false -Domap=false -Dexynos=false -Dfreedreno=false -Dtegra=false -Dvc4=false -Detnaviv=false --buildtype $LOCAL_BUILD_TYPE $LOCAL_MESON_COMPILER_OPTIONS && ninja -C $LOCAL_MESON_BUILD_DIR install

# Build mesa
echo "Building  Mesa............"
cd $WORKING_DIR/mesa
mesonclean_asneeded
meson setup $LOCAL_MESON_BUILD_DIR --buildtype $LOCAL_BUILD_TYPE -Dprefix=$LOCAL_CURRENT_WLD_PATH -Ddri3="enabled" -Dshader-cache="enabled" -Dtools="glsl,nir" -Dplatforms="x11,wayland" -Ddri-drivers="" -Dgallium-drivers="iris,virgl,swrast" -Dvulkan-drivers="intel" -Dgallium-vdpau="disabled" -Dgallium-va="disabled" -Dopengl="true" -Dglx="dri" -Dselinux="true" -Dgles1="enabled" -Dgles2="enabled" -Dglx-direct="true" -Degl="enabled" -Dllvm="disabled" $LOCAL_MESON_COMPILER_OPTIONS && ninja -C $LOCAL_MESON_BUILD_DIR install

# Build libepoxy
echo "Building libepoxy............"
cd $WORKING_DIR/libepoxy
mesonclean_asneeded
meson setup $LOCAL_MESON_BUILD_DIR  --buildtype $LOCAL_BUILD_TYPE -Dprefix=$LOCAL_CURRENT_WLD_PATH  -Dglx=yes -Dx11=true -Degl=yes $LOCAL_MESON_COMPILER_OPTIONS && ninja -C $LOCAL_MESON_BUILD_DIR install

# Build xserver
if [ $BUILD_ARCH == "--64bit" ]; then
echo "Building xserver............"
cd $WORKING_DIR/xserver
mesonclean_asneeded
meson setup $LOCAL_MESON_BUILD_DIR -Dprefix=$LOCAL_CURRENT_WLD_PATH -Dxwayland=true -Dglx=true -Dglamor=true -Dhal=false -Dlinux_acpi=false -Dxnest=false -Dxorg=false -Dxquartz=false -Dxvfb=false -Dxwin=false --buildtype $LOCAL_BUILD_TYPE $LOCAL_MESON_COMPILER_OPTIONS && ninja -C $LOCAL_MESON_BUILD_DIR install
fi


# Build minigbm
echo "Building Minigbm............"
cd $WORKING_DIR/minigbm
make clean || true
if [ $BUILD_ARCH == "--64bit" ]; then
  make CPPFLAGS="-DDRV_I915" DRV_I915=1 install DESTDIR=$LOCAL_CURRENT_WLD_PATH LIBDIR=$LOCAL_LIBDIR
else
  make CPPFLAGS="-DDRV_I915" DRV_I915=1 "CFLAGS=-m32 -msse2 -mstackrealign" "CXXFLAGS=-m32" "LDFLAGS=-m32" install DESTDIR=$LOCAL_CURRENT_WLD_PATH LIBDIR=$LOCAL_LIBDIR
fi

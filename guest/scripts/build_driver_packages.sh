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

if /scripts/guest/common_build_internal.sh $BUILD_TYPE $BUILD_TARGET $BUILD_CHANNEL
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

LOCAL_CURRENT_WLD_PATH=/opt/$LOCAL_CHANNEL/$LOCAL_BUILD_TARGET/x86
LOCAL_MESON_BUILD_DIR=build.$LOCAL_BUILD_TARGET.x86
CROSS_SETTINGS=meson-cross-i686-$LOCAL_CHANNEL-$LOCAL_BUILD_TARGET.ini

# Export environment variables
export C_INCLUDE_PATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
export CPLUS_INCLUDE_PATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
export CPATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
export PATH="$PATH:$LOCAL_CURRENT_WLD_PATH/include/:$LOCAL_CURRENT_WLD_PATH/include/libdrm/:$LOCAL_CURRENT_WLD_PATH/bin"
export ACLOCAL_PATH=$LOCAL_CURRENT_WLD_PATH/share/aclocal
export ACLOCAL="aclocal -I $ACLOCAL_PATH"
export PKG_CONFIG_PATH=$LOCAL_CURRENT_WLD_PATH/lib/pkgconfig:$LOCAL_CURRENT_WLD_PATH/share/pkgconfig:/usr/lib/i386-linux-gnu/pkgconfig:/lib/i386-linux-gnu/pkgconfig
export PKG_CONFIG_PATH_FOR_BUILD=$PKG_CONFIG_PATH
export CC=/usr/bin/i686-linux-gnu-gcc

LOCAL_COMPILER_OPTIONS="--host=i686-linux-gnu "CFLAGS=-m32" "CXXFLAGS=-m32" "LDFLAGS=-m32" --prefix=$LOCAL_CURRENT_WLD_PATH"
LOCAL_MESON_COMPILER_OPTIONS="--cross-file $CROSS_SETTINGS"

# Set Working Build directory based on the channel.
WORKING_DIR=/build/$LOCAL_CHANNEL/drivers

echo "Working Directory:" $WORKING_DIR

export PKG_CONFIG_PATH=$LOCAL_CURRENT_WLD_PATH/lib/pkgconfig:$LOCAL_CURRENT_WLD_PATH/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH:/lib/x86_64-linux-gnu/pkgconfig
env
echo "---------------------------------"

cd /build

function mesonclean_asneeded() {
if [ $BUILD_TYPE == "--clean" ]; then
  if [ -d $LOCAL_MESON_BUILD_DIR ]; then
    rm -rf $LOCAL_MESON_BUILD_DIR
  fi

  if [ -f $CROSS_SETTINGS ]; then
    rm $CROSS_SETTINGS
  fi
fi
}

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
generate_compiler_settings

meson setup $LOCAL_MESON_BUILD_DIR -Dprefix=$LOCAL_CURRENT_WLD_PATH -Dintel=true -Dradeon=false -Damdgpu=false -Dnouveau=false -Domap=false -Dexynos=false -Dfreedreno=false -Dtegra=false -Dvc4=false -Detnaviv=false --buildtype $LOCAL_BUILD_TARGET $LOCAL_MESON_COMPILER_OPTIONS && ninja -C $LOCAL_MESON_BUILD_DIR install

# Build mesa
echo "Building  Mesa............"
cd $WORKING_DIR/mesa
mesonclean_asneeded
generate_compiler_settings
meson setup $LOCAL_MESON_BUILD_DIR --buildtype $LOCAL_BUILD_TARGET -Dprefix=$LOCAL_CURRENT_WLD_PATH -Ddri3="enabled" -Dshader-cache="enabled" -Dtools="glsl,nir" -Dplatforms="x11,wayland" -Ddri-drivers="" -Dgallium-drivers="iris,virgl,swrast" -Dvulkan-drivers="intel" -Dgallium-vdpau="disabled" -Dgallium-va="disabled" -Dopengl="true" -Dglx="dri" -Dselinux="true" -Dgles1="enabled" -Dgles2="enabled" -Dglx-direct="true" -Degl="enabled" -Dllvm="disabled" $LOCAL_MESON_COMPILER_OPTIONS && ninja -C $LOCAL_MESON_BUILD_DIR install

# Build libepoxy
echo "Building libepoxy............"
cd $WORKING_DIR/libepoxy
mesonclean_asneeded
generate_compiler_settings
meson setup $LOCAL_MESON_BUILD_DIR  --buildtype $LOCAL_BUILD_TARGET -Dprefix=$LOCAL_CURRENT_WLD_PATH  -Dglx=yes -Dx11=true -Degl=yes $LOCAL_MESON_COMPILER_OPTIONS && ninja -C $LOCAL_MESON_BUILD_DIR install

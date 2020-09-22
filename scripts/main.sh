#! /bin/bash

# run-rootfs-builder.sh [USERNAME PASSWORD CONFIG_FILE MOUNT_POINT]
# Generate debian rootfs image using specified config file and mounted in the
# container at the specified path (should match mountPoint specified in json file)

BUILD_TYPE=$1
COMPONENT_ONLY_BUILDS=$2
TARGET_ARCH=$3
SYNC_SOURCE=$4
BUILD_CHANNEL=$5
BUILD_TARGET=$6
UPDATE_SYSTEM=$7
DIRECTORY_PREFIX=${8}
LOCAL_SOURCE_PWD=${9}
MOUNT_POINT=${10}

echo "Recieved Arguments...."
echo "BUILD_TYPE:" $BUILD_TYPE
echo "COMPONENT_ONLY_BUILDS:" $COMPONENT_ONLY_BUILDS
echo "TARGET_ARCH:" $TARGET_ARCH
echo "SYNC_SOURCE:" $SYNC_SOURCE
echo "BUILD_CHANNEL:" $BUILD_CHANNEL
echo "BUILD_TARGET:" $BUILD_TARGET
echo "UPDATE_SYSTEM:" $UPDATE_SYSTEM
echo "DIRECTORY_PREFIX:" $DIRECTORY_PREFIX
echo "LOCAL_SOURCE_PWD:" $LOCAL_SOURCE_PWD
echo "MOUNT_POINT:" $MOUNT_POINT
echo "--------------------------"

LOCAL_DIRECTORY_PREFIX=$DIRECTORY_PREFIX
LOCAL_BUILD_CHANNEL="--dev"
LOCAL_BUILD_TARGET="--release"
LOCAL_BUILD_TYPE=$BUILD_TYPE
LOCAL_TARGET_ARCH="--64bit"
LOG_DIR=$LOCAL_DIRECTORY_PREFIX/output/component_log

source $LOCAL_DIRECTORY_PREFIX/output/scripts/error_handler_internal.sh $LOG_DIR $LOCAL_DIRECTORY_PREFIX main_err.log $MOUNT_POINT

if [ $BUILD_TYPE != "--clean" ] && [ $BUILD_TYPE != "--incremental" ] && [ $BUILD_TYPE != "--really-clean" ]; then
  echo "Invalid Build Type. Valid Values:--clean, --incremental, --create-source-image-only --setup-initial-enviroment --really-clean"
  exit 1
fi

if [ $COMPONENT_ONLY_BUILDS != "--x11" ] && [ $COMPONENT_ONLY_BUILDS != "--wayland" ]  && [ $COMPONENT_ONLY_BUILDS != "--drivers" ] && [ $COMPONENT_ONLY_BUILDS != "--kernel" ] && [ $COMPONENT_ONLY_BUILDS != "--demos" ] && [ $COMPONENT_ONLY_BUILDS != "--all" ] && [ $COMPONENT_ONLY_BUILDS != "--vm" ]; then
  echo "Invalid value for COMPONENT_ONLY_BUILDS. Please check build_options.txt file for supported combinations."
  exit 1
fi

if [ $SYNC_SOURCE != "--true" ] && [ $SYNC_SOURCE != "--false" ]; then
  echo "Invalid request for updating channel. Valid Values: --true, --false"
  exit 1
fi

if [ $BUILD_CHANNEL != "--dev" ] && [ $BUILD_CHANNEL != "--stable" ] && [ $BUILD_CHANNEL != "--all" ]; then
 echo "Invalid Build Channel. Valid Values: --dev, --stable, --all"
 exit 1
fi

if [ $BUILD_TARGET != "--release" ] && [ $BUILD_TARGET != "--debug" ] && [ $BUILD_TARGET != "--all" ]; then
 echo "Invalid Build Channel. Valid Values: --release, --debug, --all"
 exit 1
fi

if [ $UPDATE_SYSTEM != "--true" ] && [ $UPDATE_SYSTEM != "--false" ]; then
  echo "Invalid request for updating system. Valid Values: --true, --false"
  exit 1
fi

if [ $TARGET_ARCH != "--all" ] && [ $TARGET_ARCH != "--x86_64" ] && [ $TARGET_ARCH != "--i386" ]; then
  echo "Invalid value for TARGET_ARCH2. Please check build_options.txt file for supported options."
  exit 1
fi

if [ $BUILD_CHANNEL == "--stable" ]; then
  LOCAL_BUILD_CHANNEL="--stable"
else
  if [ $BUILD_CHANNEL == "--all" ]; then
  LOCAL_BUILD_CHANNEL="--all"
  fi
fi

if [ $BUILD_TARGET == "--debug" ]; then
  LOCAL_BUILD_TARGET="--debug"
else
  if [ $BUILD_TARGET == "--all" ]; then
  LOCAL_BUILD_TARGET="--all"
  fi
fi

echo "Directory Prefix being used:" $LOCAL_DIRECTORY_PREFIX

if [ ! -e $LOCAL_SOURCE_PWD/source/source.ext4 ]; then
  echo "Failed to find Source image." $LOCAL_SOURCE_PWD
  exit 1;
fi

if [ ! -e $LOCAL_DIRECTORY_PREFIX/output/rootfs.ext4 ]; then
  echo "Failed to find Rootfs image."
  exit 1;
fi

if [ $LOCAL_BUILD_CHANNEL == "--all" ]; then
  echo "Build Tree: dev, Stable"
  if [ $BUILD_TYPE == "--really-clean" ]; then
    rm -rf $MOUNT_POINT/opt/stable
    rm -rf $MOUNT_POINT/opt/dev
    LOCAL_BUILD_TYPE="--clean"
  fi
fi

if [ $LOCAL_BUILD_CHANNEL == "--dev" ]; then
  echo "Build Tree: dev"
  if [ $BUILD_TYPE == "--really-clean" ]; then
    rm -rf $MOUNT_POINT/opt/dev
    LOCAL_BUILD_TYPE="--clean"
  fi
fi

if [ $LOCAL_BUILD_CHANNEL == "--stable" ]; then
  echo "Build Tree: Stable"
  if [ $BUILD_TYPE == "--really-clean" ]; then
    rm -rf $MOUNT_POINT/opt/stable
    LOCAL_BUILD_TYPE="--clean"
  fi
fi

if [ $LOCAL_BUILD_TARGET == "--all" ]; then
  echo "Build Target: Release, Debug"
fi

if [ $LOCAL_BUILD_TARGET == "--release" ]; then
  echo "Build Target: Release"
fi

if [ $LOCAL_BUILD_TARGET == "--debug" ]; then
  echo "Build Tree: Debug"
fi

if [ $TARGET_ARCH == "--all" ]; then
  LOCAL_TARGET_ARCH="--all"
  echo "Target Arch: x86_64, i386."
fi

if [ $TARGET_ARCH == "--i386" ]; then
  LOCAL_TARGET_ARCH="--32bit"
  echo "Target Arch: i386."
fi

if [ $TARGET_ARCH == "--x86_64" ]; then
  LOCAL_TARGET_ARCH="--64bit"
  echo "Target Arch: x86_64."
fi

if bash $LOCAL_DIRECTORY_PREFIX/output/scripts/mount_internal.sh --true --true --true  $LOCAL_DIRECTORY_PREFIX $LOCAL_SOURCE_PWD $MOUNT_POINT
  then
  echo "Mount succeeded...."
else
  echo "Failed to Mount..."
  echo "Trying to unmount all directories. Please run ./build.sh with same build options again."
  $LOCAL_DIRECTORY_PREFIX/output/scripts/unmount_internal.sh --true --true --true $LOCAL_DIRECTORY_PREFIX $MOUNT_POINT
  exit 1
fi

# Install all needed system packages.
if [ $UPDATE_SYSTEM == "--true" ]; then
  echo "Installing system packages...."
  chroot $MOUNT_POINT/ /bin/bash /build/output/scripts/system_packages_internal.sh
fi

# Update sources as needed.
if [ $SYNC_SOURCE == "--true" ]; then
  echo "Installing system packages...."
  chroot $MOUNT_POINT/ /bin/bash /build/output/scripts/sync_code_internal.sh
fi

build_x11() {
if [ $COMPONENT_ONLY_BUILDS == "--x11" ] || [ $COMPONENT_ONLY_BUILDS == "--all" ]; then
  build_target="${1}"
  build_type="${2}"
  channel="${3}"
  arch="${4}"
  if [ $LOCAL_TARGET_ARCH != "--all" ] && [ $LOCAL_TARGET_ARCH != $arch ]; then
    return 0;
  fi

  if [ $LOCAL_BUILD_CHANNEL != $channel ] && [ $LOCAL_BUILD_CHANNEL != "--all" ]; then
    return 0;
  fi

  if [ $LOCAL_BUILD_TARGET != $build_target ] && [ $LOCAL_BUILD_TARGET != "--all" ]; then
  return 0;
  fi

  chroot $MOUNT_POINT/ /bin/bash /build/output/scripts/build_x11_packages.sh $build_target $build_type $channel $arch
fi
}

build_wayland() {
if [ $COMPONENT_ONLY_BUILDS == "--wayland" ] || [ $COMPONENT_ONLY_BUILDS == "--all" ]; then
  build_target="${1}"
  build_type="${2}"
  channel="${3}"
  arch="${4}"

  if [ $LOCAL_TARGET_ARCH != "--all" ] && [ $LOCAL_TARGET_ARCH != $arch ]; then
    return 0;
  fi

  if [ $LOCAL_BUILD_CHANNEL != $channel ] && [ $LOCAL_BUILD_CHANNEL != "--all" ]; then
    return 0;
  fi

  if [ $LOCAL_BUILD_TARGET != $build_target ] && [ $LOCAL_BUILD_TARGET != "--all" ]; then
  return 0;
  fi

  chroot $MOUNT_POINT/ /bin/bash /build/output/scripts/build_wayland_packages.sh $build_target $build_type $channel $arch
fi
}

build_drivers() {
if [ $COMPONENT_ONLY_BUILDS == "--drivers" ] || [ $COMPONENT_ONLY_BUILDS == "--all" ]; then
  build_target="${1}"
  build_type="${2}"
  channel="${3}"
  arch="${4}"

  if [ $LOCAL_TARGET_ARCH != "--all" ] && [ $LOCAL_TARGET_ARCH != $arch ]; then
    return 0;
  fi

  if [ $LOCAL_BUILD_CHANNEL != $channel ] && [ $LOCAL_BUILD_CHANNEL != "--all" ]; then
    return 0;
  fi

  if [ $LOCAL_BUILD_TARGET != $build_target ] && [ $LOCAL_BUILD_TARGET != "--all" ]; then
  return 0;
  fi
  
  chroot $MOUNT_POINT/ /bin/bash /build/output/scripts/build_driver_packages.sh $build_target $build_type $channel $arch
fi
}

build_vm() {
if [ $COMPONENT_ONLY_BUILDS == "--vm" ] || [ $COMPONENT_ONLY_BUILDS == "--all" ]; then
  build_target="${1}"
  build_type="${2}"
  channel="${3}"
  arch="${4}"

  if [ $LOCAL_TARGET_ARCH != "--all" ] && [ $LOCAL_TARGET_ARCH != $arch ]; then
    return 0;
  fi

  if [ $LOCAL_BUILD_CHANNEL != $channel ] && [ $LOCAL_BUILD_CHANNEL != "--all" ]; then
    return 0;
  fi

  if [ $LOCAL_BUILD_TARGET != $build_target ] && [ $LOCAL_BUILD_TARGET != "--all" ]; then
  return 0;
  fi
  
  chroot $MOUNT_POINT/ /bin/bash /build/output/scripts/build_vm_packages.sh $build_target $build_type $channel $arch
fi
}

build_demos() {
if [ $COMPONENT_ONLY_BUILDS == "--demos" ] || [ $COMPONENT_ONLY_BUILDS == "--all" ]; then
  build_target="${1}"
  build_type="${2}"
  channel="${3}"
  arch="${4}"
  if [ $LOCAL_TARGET_ARCH != "--all" ] && [ $LOCAL_TARGET_ARCH != $arch ]; then
    return 0;
  fi

  if [ $LOCAL_BUILD_CHANNEL != $channel ] && [ $LOCAL_BUILD_CHANNEL != "--all" ]; then
    return 0;
  fi

  if [ $LOCAL_BUILD_TARGET != $build_target ] && [ $LOCAL_BUILD_TARGET != "--all" ]; then
  return 0;
  fi
  
  chroot $MOUNT_POINT/ /bin/bash /build/output/scripts/build_demos.sh $build_target $build_type $channel $arch
fi
}

# Build all UMD and user space libraries.
#------------------------------------Dev Channel-----------"
echo "Building User Mode Graphics Drivers..."
#Debug
build_x11 --debug $LOCAL_BUILD_TYPE --dev --64bit
build_wayland --debug $LOCAL_BUILD_TYPE --dev --64bit
build_drivers --debug $LOCAL_BUILD_TYPE --dev --64bit
build_vm --debug $LOCAL_BUILD_TYPE --dev --64bit
build_demos --debug $LOCAL_BUILD_TYPE --dev --64bit
build_x11 --debug $LOCAL_BUILD_TYPE --dev --32bit
build_wayland --debug $LOCAL_BUILD_TYPE --dev --32bit
build_drivers --debug $LOCAL_BUILD_TYPE --dev --32bit

# Release Builds.
build_x11 --release $LOCAL_BUILD_TYPE --dev --64bit
build_wayland --release $LOCAL_BUILD_TYPE --dev --64bit
build_drivers --release $LOCAL_BUILD_TYPE --dev --64bit
build_vm --release $LOCAL_BUILD_TYPE --dev --64bit
build_demos --release $LOCAL_BUILD_TYPE --dev --64bit
build_x11 --release $LOCAL_BUILD_TYPE --dev --32bit
build_wayland --release $LOCAL_BUILD_TYPE --dev --32bit
build_drivers --release $LOCAL_BUILD_TYPE --dev --32bit

build_demos --debug $LOCAL_BUILD_TYPE --dev --64bit
build_demos --release $LOCAL_BUILD_TYPE --dev --64bit
#----------------------------Dev Channel ends-----------------

#------------------------------------Stable Channel-----------"
#Debug
build_x11 --debug $LOCAL_BUILD_TYPE --stable --64bit
build_wayland --debug $LOCAL_BUILD_TYPE --stable --64bit
build_drivers --debug $LOCAL_BUILD_TYPE --stable --64bit
build_vm --debug $LOCAL_BUILD_TYPE --stable --64bit
build_demos --debug $LOCAL_BUILD_TYPE --stable --64bit
build_x11 --debug $LOCAL_BUILD_TYPE --stable --32bit
build_wayland --debug $LOCAL_BUILD_TYPE --stable --32bit
build_drivers --debug $LOCAL_BUILD_TYPE --stable --32bit

# Release Builds.
build_x11 --release $LOCAL_BUILD_TYPE --stable --64bit
build_wayland --release $LOCAL_BUILD_TYPE --stable --64bit
build_drivers --release $LOCAL_BUILD_TYPE --stable --64bit
build_vm --release $LOCAL_BUILD_TYPE --stable --64bit
build_demos --release $LOCAL_BUILD_TYPE --stable --64bit
build_x11 --release $LOCAL_BUILD_TYPE --stable --32bit
build_wayland --release $LOCAL_BUILD_TYPE --stable --32bit
build_drivers --release $LOCAL_BUILD_TYPE --stable --32bit

build_demos --debug $LOCAL_BUILD_TYPE --stable --64bit
build_demos --release $LOCAL_BUILD_TYPE --stable --64bit
#----------------------------stable Channel ends-----------------

if [ $COMPONENT_ONLY_BUILDS == "--all" ] || [ $COMPONENT_ONLY_BUILDS == "--kernel" ]; then
  if [ $LOCAL_BUILD_CHANNEL == "--dev" ] || [ $LOCAL_BUILD_CHANNEL == "--all" ]; then
    chroot $MOUNT_POINT/ /bin/bash /build/output/scripts/build_kernel.sh --release $LOCAL_BUILD_TYPE --dev
  fi

  if [ $LOCAL_BUILD_CHANNEL == "--stable" ] || [ $LOCAL_BUILD_CHANNEL == "--all" ]; then
    chroot $MOUNT_POINT/ /bin/bash /build/output/scripts/build_kernel.sh --release $LOCAL_BUILD_TYPE --stable
  fi
fi


if bash $LOCAL_DIRECTORY_PREFIX/output/scripts/unmount_internal.sh --true --true --true $LOCAL_DIRECTORY_PREFIX $MOUNT_POINT
then
  echo "unmounted all directories...."
else
  echo "Failed to unmount..."
  exit 1
fi

echo "Done!"

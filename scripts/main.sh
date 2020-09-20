#! /bin/bash

# run-rootfs-builder.sh [USERNAME PASSWORD CONFIG_FILE MOUNT_POINT]
# Generate debian rootfs image using specified config file and mounted in the
# container at the specified path (should match mountPoint specified in json file)

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

BUILD_ENVIRONMENT=$1
INITIAL_BUILD_SETUP=$2
BUILD_TYPE=$3
COMPONENT_ONLY_BUILDS=$4
TARGET_ARCH=$5
SYNC_SOURCE=$6
BUILD_CHANNEL=$7
BUILD_TARGET=$8
UPDATE_SYSTEM=$9
LOGDIR=$10
MOUNT_POINT=${11}
CONFIG_FILE=${12:-"image.json"}


echo "Recieved Arguments...."
echo "BUILD_ENVIRONMENT:" $BUILD_ENVIRONMENT
echo "INITIAL_BUILD_SETUP:" $INITIAL_BUILD_SETUP
echo "BUILD_TYPE:" $BUILD_TYPE
echo "TARGET_ARCH:" $TARGET_ARCH
echo "COMPONENT_ONLY_BUILDS:" $COMPONENT_ONLY_BUILDS
echo "SYNC_SOURCE:" $SYNC_SOURCE
echo "BUILD_CHANNEL:" $BUILD_CHANNEL
echo "BUILD_TARGET:" $BUILD_TARGET
echo "UPDATE_SYSTEM:" $UPDATE_SYSTEM
echo "MOUNT_POINT:" $MOUNT_POINT
echo "--------------------------"

LOCAL_DIRECTORY_PREFIX=/build
LOCAL_BUILD_CHANNEL="--dev"
LOCAL_BUILD_TARGET="--release"
LOCAL_SRC_CONFIG_FILE="source.json"
LOCAL_BUILD_TYPE=$BUILD_TYPE
LOCAL_TARGET_ARCH="--64bit"

if [ $LOCAL_BUILD_TYPE == "--really-clean" ]; then
  COMPONENT_ONLY_BUILDS="--all"
fi

if [ $BUILD_ENVIRONMENT != "--chroot" ] && [ $BUILD_ENVIRONMENT != "--docker" ]; then
  echo "Invalid Build Environment. Valid Values:--chroot, --docker"
  exit 1
fi

if [ $BUILD_TYPE != "--clean" ] && [ $BUILD_TYPE != "--incremental" ] && [ $BUILD_TYPE != "--really-clean" ]; then
  echo "Invalid Build Type. Valid Values:--clean, --incremental, --create-source-image-only --setup-initial-enviroment --really-clean"
  exit 1
fi

if [ $INITIAL_BUILD_SETUP != "--none" ]  && [ $INITIAL_BUILD_SETUP != "--create-rootfs-image-only" ] && [ $INITIAL_BUILD_SETUP != "--create-source-image-only" ] && [ $INITIAL_BUILD_SETUP != "--setup-initial-environment" ] && [ $INITIAL_BUILD_SETUP != "--bootstrap" ]; then
  echo "Invalid INITIAL_BUILD_SETUP. Please check build_options.txt file for supported combinations."
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

if [ $BUILD_ENVIRONMENT == "--docker" ]; then
  LOCAL_DIRECTORY_PREFIX=/app
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
if [ $LOCAL_BUILD_CHANNEL == "all" ]; then
  echo "Build Tree: dev, Stable"
  if [ $BUILD_TYPE == --really-clean ]; then
    rm -rf $MOUNT_POINT/opt/
    rm -rf $MOUNT_POINT/opt/dev
    LOCAL_BUILD_TYPE="--clean"
  fi
fi

if [ $LOCAL_BUILD_CHANNEL == "dev" ]; then
  echo "Build Tree: dev"
  if [ $BUILD_TYPE == --really-clean ]; then
    rm -rf $MOUNT_POINT/opt/dev
    LOCAL_BUILD_TYPE="--clean"
  fi
fi

if [ $LOCAL_BUILD_CHANNEL == "stable" ]; then
  echo "Build Tree: Stable"
  if [ $BUILD_TYPE == --really-clean ]; then
    rm -rf $MOUNT_POINT/opt/stable
    LOCAL_BUILD_TYPE="--clean"
  fi
fi

if [ $LOCAL_BUILD_TARGET == "all" ]; then
  echo "Build Target: Release, Debug"
fi

if [ $LOCAL_BUILD_TARGET == "release" ]; then
  echo "Build Target: Release"
fi

if [ $LOCAL_BUILD_TARGET == "debug" ]; then
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

mount() {
mount_system_dir="${1}"
mount_source="${2}"
mount_output="${3}"
if bash $LOCAL_DIRECTORY_PREFIX/output/scripts/mount_internal.sh $mount_system_dir $mount_source $mount_output $BUILD_ENVIRONMENT $MOUNT_POINT
  then
  echo "Mount succeeded...."
else
  echo "Failed to Mount..."
  echo "Removing rootfs image. Please run ./build.sh with same build options again."
  rm -rf $LOCAL_DIRECTORY_PREFIX/output/rootfs.ext4
  exit 1
fi
}

unmount() {
unmount_system_dir="${1}"
unmount_source="${2}"
unmount_output="${3}"
if bash $LOCAL_DIRECTORY_PREFIX/output/scripts/unmount_internal.sh $unmount_system_dir $unmount_source $unmount_output $BUILD_ENVIRONMENT $MOUNT_POINT
then
  echo "unmounted all directories...."
else
  echo "Failed to unmount..."
  exit 1
fi
}

# Generate initial rootfs image.
if [ $INITIAL_BUILD_SETUP == "--create-rootfs-image-only" ]; then
  echo "Generating rootfs image"
  python3 $LOCAL_DIRECTORY_PREFIX/output/scripts/create_image_internal.py --spec  $LOCAL_DIRECTORY_PREFIX/config/$CONFIG_FILE --create

  if [ ! -e $LOCAL_DIRECTORY_PREFIX/output/rootfs.ext4 ]; then
    echo "Failed to create Rootfs image."
    exit 1;
  fi

  exit 0;
fi

if [ $INITIAL_BUILD_SETUP == "--bootstrap" ]; then
  if [ ! -e $LOCAL_DIRECTORY_PREFIX/output/rootfs.ext4 ]; then
    echo "Failed to create Rootfs image."
    exit 1;
  fi

  echo "Bootstrapping debian userspace"
  mount "--false" "--false" "--false"
  debootstrap --arch=amd64 testing $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT
  unmount "--false" "--false" "--false"
  echo "Bootstrap succeeded...."
  exit 0;
fi

# We should have mounted $LOCAL_DIRECTORY_PREFIX/output/scripts to /build/output/scripts in mount_internal.sh
if [ $INITIAL_BUILD_SETUP == "--setup-initial-environment" ]; then
  mount "--true" "--false" "--true"
  echo "Copying user configuration script..."
  mkdir -p $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/deploy/config
  cp $LOCAL_DIRECTORY_PREFIX/output/scripts/create_users_internal.py $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/deploy/
  cp $LOCAL_DIRECTORY_PREFIX/config/users.json $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/deploy/config/
  if [ ! -e  $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/deploy/config/users.json ]; then
    echo "User configuration file not found."
    unmount "--true" "--false" "--true"
    exit 1
  fi

  if [ ! -e  $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/deploy/create_users_internal.py ]; then
    echo "User configuration file not found."
    unmount "--true" "--false" "--true"
    exit 1
  fi

  echo "Installing needed dependencies..."
  chroot $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/ ls -a  /build/output/scripts/
  chroot $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/ /bin/bash /build/output/scripts/system_packages_internal.sh

  echo "Configuring the user..."
    chroot $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/ ls -a /deploy
  chroot $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/ python3 /deploy/create_users_internal.py --spec /deploy/config/users.json false
  echo "Configuring rootfs..."
  cp -rvf $LOCAL_DIRECTORY_PREFIX/config/guest/* $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/
  chroot $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/ ls -a usr/lib/systemd/test/
  echo "Enabling Needed Services..."
  chroot $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/ python3 /deploy/create_users_internal.py --spec /deploy/config/users.json true
  rm -rf $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/deploy/
  unmount "--true" "--false" "--true"
  exit 0;
fi

if [ $INITIAL_BUILD_SETUP == "--create-source-image-only" ]; then
  echo "Generating source image"
  if [ -e $LOCAL_DIRECTORY_PREFIX/source/source.ext4 ]; then
    echo "Source image already exists. Please check." $PWD
    exit 1;
  fi
  python3 $LOCAL_DIRECTORY_PREFIX/output/scripts/create_image_internal.py --spec $LOCAL_DIRECTORY_PREFIX/config/$LOCAL_SRC_CONFIG_FILE --create

  if [ ! -e $LOCAL_DIRECTORY_PREFIX/source/source.ext4 ]; then
    echo "Failed to create Source image." $PWD
    exit 1;
  fi

  if [ ! -e $LOCAL_DIRECTORY_PREFIX/output/rootfs.ext4 ]; then
    echo "Failed to create Rootfs image."
    exit 1;
  fi

  echo "Cloning code..."
  mount "--true" "--true" "--true"
  chroot $LOCAL_DIRECTORY_PREFIX/$MOUNT_POINT/ /bin/bash /build/output/scripts/sync_code_internal.sh
  unmount "--true" "--true" "--true"
  exit 0;
else
  if [ ! -e $LOCAL_DIRECTORY_PREFIX/source/source.ext4 ]; then
    echo "Failed to find Source image." $PWD
    exit 1;
  fi

  if [ ! -e $LOCAL_DIRECTORY_PREFIX/output/rootfs.ext4 ]; then
    echo "Failed to find Rootfs image."
    exit 1;
  fi

  mount "--true" "--true" "--true"
fi

# Install all needed system packages.
if [ $UPDATE_SYSTEM == "--true" ]; then
  echo "Installing system packages...."
  chroot $MOUNT_POINT/ /bin/bash /build/output/scripts/system_packages_internal.sh > >(tee -a $LOCAL_DIRECTORY_PREFIX/output/$LOGDIR/system_package_update.log) 2> >(tee -a $LOCAL_DIRECTORY_PREFIX/output/$LOGDIR/system_package_update.err) >&2
fi

# Update sources as needed.
if [ $SYNC_SOURCE == "--true" ]; then
  echo "Installing system packages...."
  chroot $MOUNT_POINT/ /bin/bash /build/output/scripts/sync_code_internal.sh > >(tee -a $LOCAL_DIRECTORY_PREFIX/output/$LOGDIR/sync_code.log) 2> >(tee -a $LOCAL_DIRECTORY_PREFIX/output/$LOGDIR/sync_code.err) >&2
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
  LOG_FILE_NAME=x11+"_"+$build_target+"_"+$build_type"_"+$channel+"_"+$arch

  chroot $MOUNT_POINT/ /bin/bash /build/output/scripts/build_x11_packages.sh $build_target $build_type $channel $arch > >(tee -a $LOCAL_DIRECTORY_PREFIX/output/$LOGDIR/$LOG_FILE_NAME.log) 2> >(tee -a $LOCAL_DIRECTORY_PREFIX/output/$LOGDIR/$LOG_FILE_NAME.err) >&2
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
  
    LOG_FILE_NAME=wayland+"_"+$build_target+"_"+$build_type"_"+$channel+"_"+$arch
  chroot $MOUNT_POINT/ /bin/bash /build/output/scripts/build_wayland_packages.sh $build_target $build_type $channel $arch > >(tee -a $LOCAL_DIRECTORY_PREFIX/output/$LOGDIR/$LOG_FILE_NAME.log) 2> >(tee -a $LOCAL_DIRECTORY_PREFIX/output/$LOGDIR/$LOG_FILE_NAME.err) >&2
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
  
  LOG_FILE_NAME=driver+"_"+$build_target+"_"+$build_type"_"+$channel+"_"+$arch
  chroot $MOUNT_POINT/ /bin/bash /build/output/scripts/build_driver_packages.sh $build_target $build_type $channel $arch > >(tee -a $LOCAL_DIRECTORY_PREFIX/output/$LOGDIR/$LOG_FILE_NAME.log) 2> >(tee -a $LOCAL_DIRECTORY_PREFIX/output/$LOGDIR/$LOG_FILE_NAME.err) >&2
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
  
  LOG_FILE_NAME=vm+"_"+$build_target+"_"+$build_type"_"+$channel+"_"+$arch
  chroot $MOUNT_POINT/ /bin/bash /build/output/scripts/build_vm_packages.sh $build_target $build_type $channel $arch > >(tee -a $LOCAL_DIRECTORY_PREFIX/output/$LOGDIR/$LOG_FILE_NAME.log) 2> >(tee -a $LOCAL_DIRECTORY_PREFIX/output/$LOGDIR/$LOG_FILE_NAME.err) >&2
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
  
  LOG_FILE_NAME=demos+"_"+$build_target+"_"+$build_type"_"+$channel+"_"+$arch
  chroot $MOUNT_POINT/ /bin/bash /build/output/scripts/build_demos.sh $build_target $build_type $channel $arch > >(tee -a $LOCAL_DIRECTORY_PREFIX/output/$LOGDIR/$LOG_FILE_NAME.log) 2> >(tee -a $LOCAL_DIRECTORY_PREFIX/output/$LOGDIR/$LOG_FILE_NAME.err) >&2
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
    chroot $MOUNT_POINT/ /bin/bash /build/output/scripts/build_kernel.sh --release $LOCAL_BUILD_TYPE --dev > >(tee -a $LOCAL_DIRECTORY_PREFIX/output/$LOGDIR/kernel_$LOCAL_BUILD_CHANNEL.log) 2> >(tee -a $LOCAL_DIRECTORY_PREFIX/output/$LOGDIR/kernel_$LOCAL_BUILD_CHANNEL.err) >&2
  fi

  if [ $LOCAL_BUILD_CHANNEL == "--stable" ] || [ $LOCAL_BUILD_CHANNEL == "--all" ]; then
    chroot $MOUNT_POINT/ /bin/bash /build/output/scripts/build_kernel.sh --release $LOCAL_BUILD_TYPE --stable > >(tee -a $LOCAL_DIRECTORY_PREFIX/output/$LOGDIR/kernel_$LOCAL_BUILD_CHANNEL.log) 2> >(tee -a $LOCAL_DIRECTORY_PREFIX/output/$LOGDIR/kernel_$LOCAL_BUILD_CHANNEL.err) >&2
  fi
fi


unmount "--true" "--true" "--true"

echo "Done!"

#! /bin/bash

# run-rootfs-builder.sh USERNAME PASSWORD [CONFIG_FILE] [MOUNT_POINT]
# Generate debian rootfs image using specified config file and mounted in the
# container at the specified path (should match mountPoint specified in json file)

USER=${1:-"test"}
PASS=${2:-"test0000"}
CONFIG_FILE=${3:-"config/image.json"}
MOUNT_POINT=${4:-"mount/"}

if [ ! -e "$MOUNT_POINT" ]; then
    mkdir -p "$MOUNT_POINT"
fi

echo "Generating rootfs image"
python3 scripts/create-image.py --spec $CONFIG_FILE

echo "Bootstrapping debian userspace"
debootstrap --arch=amd64 testing $MOUNT_POINT

echo "Copying user configuration script..."
cp scripts/user.sh $MOUNT_POINT/user.sh
echo "Configuring the user..."
chroot $MOUNT_POINT/ /bin/bash /user.sh $USER $PASS
rm $MOUNT_POINT/user.sh

echo "Configuring rootfs..."
cp -rf config/guest/* $MOUNT_POINT/

echo "Copying script to install needed system packages in rootfs..."
cp scripts/system.sh $MOUNT_POINT/system.sh
echo "Installing system packages in rootfs...."
chroot $MOUNT_POINT/ /bin/bash /system.sh
rm $MOUNT_POINT/system.sh

echo "Copying script to build Graphics drivers and other packages..."
mount -t proc /proc $MOUNT_POINT/proc
mount -o bind /dev/shm $MOUNT_POINT/dev/shm
cp -rf config/patches $MOUNT_POINT/build/
cp scripts/builder.sh $MOUNT_POINT/builder.sh
echo "Building Graphics Drivers..."
chroot $MOUNT_POINT/ /bin/bash /builder.sh
rm $MOUNT_POINT/builder.sh

echo "Unmounting image"
python3 scripts/create-image.py --spec $CONFIG_FILE --unmount

echo "Done!"

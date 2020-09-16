# Scripts
This directory has all the scripts that are either used to generate the containers
or run within the containers to generate the rootfs images. Any new scripts that
are to go into the container must also be included in the [dockerfiles](../dockerfiles/).

## Primary scripts

### `build-rootfs-builder-container.sh`
Generates rootfs-builder docker container and tags it.

### `run-rootfs-builder.sh`
#### Usage: [USERNAME PASSWORD CONFIG_FILE MOUNT_POINT]
Main script in the rootfs-builder container that generates the rootfs images

### `create-image.py`
#### Usage: --spec JSONFILE [--create] [--unmount] [--mount]
Helper python script that generates the image files. Configured with [image.json](../default-config/image.json)

### `create-users.py`
#### Usage: --spec JSONFILE
Helper python script that can be deployed inside rootfs to create users specified
in the json file. Configured with [users.json](../default-config/users.json)

### `configure-host-network.sh`
Wizard for configuring iptables on the VM host machine.

## Support scripts

### `configure-iptables.sh`
Generate and apply iptables config to be used in VM guest.

### `build-setup.sh.sh`
Sets up Rust, repotool in rootfs and clones all needed sources in build/.

### `services.sh`
Enables the Sommelier services in rootfs

### `system-packages.sh`
Used to configure rootfs with all the packages needed for build and services.

### `user-configuration.sh`
Shell script to bootstrap the `create-users.py` script from within chroot
environment.

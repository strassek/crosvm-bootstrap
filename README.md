# Enable Wayland on Ubuntu
Execute below steps on Ubuntu Desktop but not via remote ssh
Open /etc/gdm3/custom.conf and ensure WaylandEnable=false is commented.
Logout and click on the gear button and select option "Ubuntu on Wayland"
once booted to desktop, make sure "echo $WAYLAND_DISPLAY" = wayland-0.

## Quickstart
To build your system, you will need to follow these instructions:

1. Install all system dependencies and setup Docker:
```bash
./check-environment.sh 
```
2. Fetch the code:
```bash
./sync_code.sh
```
3. Kick off the build of the container and generate
a rootfs image using the default settings. 
```bash
./build.sh -b --all
```
Build Guest Only:
```bash
./build.sh -b --clean -c --guest
```
Build Container Only:
```bash
./build.sh -b --clean -c --container
```
Build Kernel Only:
```bash
./build.sh -b --clean -c --kernel
```
Incremental Builds:
./build.sh -b --update -c <component> -s <sub-component>
```bash
./build.sh -b --update -c --host -s --vm

4. Check build/launch/README.md for instructions to run the VM and container.

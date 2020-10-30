# crosvm-bootstrap

A collection of scripts and dockerfiles to generate Docker images meant to host
[crosvm](https://chromium.googlesource.com/chromiumos/platform/crosvm/).

# Enable Wayland on Ubuntu
Execute below steps on Ubuntu Desktop but not via remote ssh
Open /etc/gdm3/custom.conf and ensure WaylandEnable=false is commented.
Logout and click on the gear button and select option "Ubuntu on Wayland"
once booted to desktop, make sure "echo $WAYLAND_DISPLAY" = wayland-0.

## Quickstart
To build your system, you will need to follow these instructions:

1. Install all system dependencies:
```bash
./tools/install_system_dependencies.sh
```
2. Fetch the code:
```bash
./sync_code.sh
```
3. Kick off the build of the container and generate
a rootfs image using the default settings. 
```bash
./build.sh --rebuild-all
```
4. Launch the vm and Guest Container:
```bash
cd build/launch
./launcher.sh
To enable GPU pass through support:
./launcher.sh --true
```
5. Once inside container you can run demo application using the launch statment such as
the following for X11:
```bash
launch-x es2gears_wayland
```
6. Re-launch Container within container: 
This is really needed only if you need to exit the container within the VM for any reason.
```bash
launch
```

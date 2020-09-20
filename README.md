# crosvm-bootstrap

A collection of scripts and dockerfiles to generate Docker images meant to host
[crosvm](https://chromium.googlesource.com/chromiumos/platform/crosvm/).

## Quickstart
1. Run `./check-environment.sh` to make sure your system has docker set up
correctly.
2. Run `./build.sh` to kick off the build of the container and generate
a rootfs image using the default settings.
3. Run ./launcher.sh to launch the vm.

## How to customize
Edit files in `default-config/` to change the default settings for the images 
generated by the container. Override the config in an existing container image 
by mounting a the your `default-config/` with your modified config files on
`/app/config` in the container.

Run the `build-rootfs-builder-container.sh` script to generate your Docker
container.

For more information about how to utilize the container, refer to the
[Dockerfile README](dockerfiles/README.md)

#! /bin/bash

# setup-containers.sh
# Set up build environment for docker container that generates Debian rootfs
# then calls docker build.

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value


exec docker run -t -i -e BASH_ENV=/etc/profile -e container=docker --privileged -v /dev:/dev -h game-fast --storage-opt size=120G -e XDG_RUNTIME_DIR=/tmp -e PATH=/intel/bin:$PATH -u $(whoami) game-fast:latest bash --login

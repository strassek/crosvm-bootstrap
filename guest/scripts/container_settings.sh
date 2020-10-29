#! /bin/bash

# container_settings.sh
# Set up build environment for docker container that generates Debian rootfs
# then calls docker build.

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

if [[ ! -e /intel/bin/update-containers ]]; then
  echo "linking"
  ln -s /intel/bin/setup-containers.sh /intel/bin/update-containers
  chmod 0664 /intel/bin/setup-containers.sh
  chmod 0664 /intel/bin/update-containers
fi

if [[ ! -e /intel/bin/launch ]]; then
  echo "linking"
  ln -s /intel/bin/launch.sh /intel/bin/launch
  chmod 0664 /intel/bin/launch.sh
  chmod 0664 /intel/bin/launch
fi

chown -R test:test /intel

echo "containers created2"

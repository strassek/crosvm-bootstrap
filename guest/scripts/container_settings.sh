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

if [[ ! -e /intel/bin/launch-container ]]; then
  echo "linking"
  ln -s /intel/bin/launch-container.sh /intel/bin/launch-container
  chmod 0664 /intel/bin/launch-container.sh
  chmod 0664 /intel/bin/launch-container
fi

sudo ln -s /intel/bin/container/app-launcher.sh /intel/bin/container/launch
sudo ln -s /intel/bin/container/app-launcher-x.sh /intel/bin/container/launch-x
sudo ln -s /intel/bin/container/headless.sh /intel/bin/container/launch-h
sudo ln -s /intel/bin/container/igt_run.sh /intel/bin/container/igt_run

chown -R test:test /intel

echo "containers created2"

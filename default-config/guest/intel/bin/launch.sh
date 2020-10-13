#! /bin/bash

# setup-containers.sh
# Set up build environment for docker container that generates Debian rootfs
# then calls docker build.

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value


docker exec -it game-fast-container  /bin/bash

if [[ "$(docker images -q game-fast:latest 2> /dev/null)" != "" ]]; then
  docker rmi -f game-fast:latest || true
fi

echo "commiting game-fast"
docker commit game-fast-container game-fast:latest


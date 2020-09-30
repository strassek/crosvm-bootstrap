#! /bin/bash

DEBOOTSTRAP_CMD=`which debootstrap`
if [ $? -ne 0 ]; then
    echo "debootstrap does not appear to be installed or it is not found in PATH."
    echo "Please install debootstrap and ensure it is on the PATH."
    exit 1
fi

DOCKER_CMD=`which docker`
if [ $? -ne 0 ]; then
    echo "Docker does not appear to be installed or it is not found in PATH."
    echo "Please install Docker and ensure it is on the PATH."
    exit 1
else
    DOCKER_SOCK=`ls /var/run/docker.sock 2>/dev/null`
    if [ -z "$DOCKER_SOCK" ]; then
        echo "Docker does not appear to be running."
        exit 1
    fi
fi

groups `whoami` | grep docker 2>&1 > /dev/null
if [ $? -ne 0 ]; then
    while true; do
        read -p "Do you want to be added to the docker user group? [Y/n]: " add_docker
        case $add_docker in
            [Yy]* ) sudo usermod -aG docker `whoami`; break;;
            [Nn]* ) echo "You should add yourself to the docker group to avoid needing sudo"; break;;
            * ) echo "I didn't understand that...";;
        esac
    done
fi

echo "Your system seems ready to go."

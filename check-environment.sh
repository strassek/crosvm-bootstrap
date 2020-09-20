#! /bin/bash

DOCKER_CMD=`which docker`
if [ ! -z $? ]; then
    echo "Docker does not appear to be installed or it is not found in PATH."
    echo "Please install Docker and ensure it is on the PATH."
    exit 1
else
    DOCKER_SOCK=`ls /var/run/docker.sock 2>/dev/null`
    if [ -z "$DOCKER_SOCK" ]; then
        echo "Docker does not appear to be running."
        exit 1
fi

groups | grep docker 2>&1 > /dev/null
if [ ! -z $? ]; then
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
echo "Start the build with clean-build.sh"

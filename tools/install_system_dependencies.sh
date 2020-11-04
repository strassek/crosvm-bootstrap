#! /bin/bash

###################################################################
#Script to install all needed system dependencies.
###################################################################

###### exit on any script line that fails #########################
set -o errexit
###### bail on any unitialized variable reads #####################
set -o nounset
###### bail on failing commands before last pipe #################
set -o pipefail
###### Use this to ignore Errors for certian commands ###########
EXIT_CODE=0

######Globals ####################################################
LOCAL_OS=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
###############################################################################
##install_package()
###############################################################################
function install_package() {
	package_name="${1}"
	echo "installing:" $package_name "----------------"
	if [[ "$LOCAL_OS" == *"CentOS"* ]]; then
		sudo yum install $package_name -y
	else
  		sudo apt-get install -y $package_name
	fi
  	echo "---------------------"
}

###############################################################################
##main()
###############################################################################
install_package git 
install_package curl 
install_package ca-certificates  

if [[ "$LOCAL_OS" == *"CentOS"* ]]; then
	install_package yum-utils
	#install_package debian-keyring-2017.5-2.el7.noarch
	install_package gnome-session-wayland-session
	install_package podman-docker
	if [[ ! -e /usr/share/debootstrap/scripts/ ]]; then
		sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
		install_package debootstrap.noarch
	fi

	if [[ ! -e /usr/share/debootstrap/scripts/focal ]]; then
		cd /usr/share/debootstrap/scripts/
		sudo ln -s eoan focal
		cd -
	fi

	install_package debian-archive-keyring 
else
	install_package docker 
	install_package docker.io 
	install_package docker-compose
	install_package debian-archive-keyring 
	install_package debootstrap
	install_package gnome-session-wayland
fi

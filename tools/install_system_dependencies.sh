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

###############################################################################
##install_package()
###############################################################################
function install_package() {
	package_name="${1}"
	if [[ ! "$(dpkg -s $package_name)" ]]; then
  		echo "installing:" $package_name "----------------"
  		sudo apt-get install -y  --no-install-recommends --no-install-suggests $package_name
  		sudo apt-mark hold $package_name
  		echo "---------------------"
	else
  		echo $package_name "is already installed."
	fi
}

###############################################################################
##main()
###############################################################################
install_package git 
install_package curl 
install_package libncurses-dev 
install_package libssl-dev 
install_package ccache 
install_package bison 
install_package flex 
install_package libelf-dev 
install_package build-essential 
install_package python3 
install_package dkms 
install_package libudev-dev 
install_package libpci-dev 
install_package libiberty-dev autoconf
install_package docker 
install_package docker.io 
install_package docker-compose 
install_package pciutils 
install_package debian-archive-keyring 
install_package zlib1g-dev 
install_package ca-certificates 
install_package debootstrap 
install_package gnome-session-wayland

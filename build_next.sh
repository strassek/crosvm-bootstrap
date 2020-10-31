#! /bin/bash

############ exit on any script line that fails###############################
set -o errexit
############ bail on any unitialized variable reads###########################
set -o nounset
############ bail on failing commands before last pipe########################
set -o pipefail

###############################################################################
# Help
###############################################################################
Help()
{
	#Display Help
	echo "Usage: build.sh [-b|h|c] [params]"
	echo "-h			   Print help"
	echo "-b			   --all|clean|update"
	echo "-c  			   --host|guest|game-fast|kernel"
}

###############################################################################
# Parseopt1
###############################################################################
Parseopt1()
{
	case "$1" in
		'--all' )
				;;
		'--clean' )
				;;
		'--update' )
				;;
		*) 
				echo "Invalid argument passed $1"
				Help
				exit 1
				;;
	esac
	echo "argument passed: $1"
		
}

###############################################################################
# Parseopt2
###############################################################################
Parseopt2()
{
	case "$1" in
		'--host' )
				;;
		'--guest' )
				;;
		'--game-fast' )
				;;
		'--kernel' )
				;;
		*) 
				echo "Invalid argument passed $1"
				Help
				exit 1
				;;
	esac
	echo "argument passed: $1"
}

###############################################################################
# Setup build env
###############################################################################
Envsetup()
{
	local buildtype="$1"
	local basedir="$2"
echo "env setup1" $buildtype $basedir
	if [ $buildtype == "--clean" ] ; then

		rm -rf $basedir/build/
	fi
	echo "env setup2"
	if [ $buildtype == "--all" ] ; then
		rm -rf $basedir/build/
	fi
	
	if [ ! -e $basedir/build ]; then
		mkdir $basedir/build
	fi
	
	if [ -e $basedir/build/config ]; then
  		rm -rf $basedir/build/config
	fi
	
	if [ -e $basedir/build/rootfs ]; then
  		rm -rf $basedir/build/rootfs
	fi
	
	if [ -e $basedir/build/scripts ]; then
  		rm -rf $basedir/build/scripts/common
	fi

	mkdir -p $basedir/build/containers
	mkdir -p $basedir/build/config
	mkdir -p $basedir/build/scripts/common
	mkdir -p $basedir/build/scripts/guest
	mkdir -p $basedir/build/scripts/host
	mkdir -p $basedir/build/scripts/game-fast
	mkdir -p $basedir/build/rootfs

	cp -rf $basedir/rootfs build/
	cp -rf $basedir/default-config $basedir/build/config
	cp -rf $basedir/common/scripts/*.* $basedir/build/scripts/common
	cp -rf $basedir/guest/scripts/*.* $basedir/build/scripts/guest
	cp -rf $basedir/host/scripts/*.* $basedir/build/scripts/host
	cp -rf $basedir/game_fast/scripts/*.* $basedir/build/scripts/game-fast
	echo "env setup"
}
	
		
###############################################################################
# Main
###############################################################################

###################GLOBAL's####################################################
BASE_DIR=$PWD
#####BUILD_TYPE --all/--clean/--update
BUILD_TYPE="--none"
#####COMPONENT_TARGET --rootfs/--common-libraries/--host/--guest/--kernel/--all
COMPONENT_TARGET="--none"
#####BUILD_CHANNEL --dev/--stable
BUILD_CHANNEL="--stable"
#####BUILD_TARGET --release/--debug
BUILD_TARGET="--release"
#####Sub Components Build Type
COMPONENT_ONLY_BUILDS="--all"


while getopts ":b:c:h" option; do
   case $option in
      h )
         Help
         exit;;
	  b )
		Parseopt1 $OPTARG
		BUILD_TYPE=$OPTARG
		COMPONENT_TARGET="--none"
		echo "KK: check1"
		;;
	 c )
		Parseopt2 $OPTARG
		BUILD_TYPE="--none"
		COMPONENT_TARGET=$OPTARG
		echo "KK: check2"
		;;
	  \?)
		echo "Invalid Option: -$OPTARG" >&2
		Help
		exit 1
		;;	
	  :)
		echo "Option:-$OPTARG requires an argument" >&2
		Help
		exit 1
		;;	
   esac
done

#TODO fix when run only ./build.sh

echo "KK: check3"
Envsetup $BUILD_TYPE $BASE_DIR

##########################Local Build State For Host##############################
LOCAL_REGENERATE=$COMPONENT_TARGET

echo "KK: final $BASE_DIR, $BUILD_TYPE, $COMPONENT_TARGET, $BUILD_CHANNEL, $BUILD_TARGET $COMPONENT_ONLY_BUILDS"
##########################Build Host Rootfs Image############################## 
if bash $BASE_DIR/rootfs/create_rootfs.sh $BASE_DIR 'host' '--really-clean' "5000" ; then
	echo “Rootfs: Operation $BUILD_TYPE/$COMPONENT_TARGET Success.”    
	LOCAL_REGENERATE='--rebuild-all'                                                            
else                                                                                                         
	echo “Failed to build Base rootfs, exit status: $?”                                      
	exit 1                                                                                                     
fi

if bash $BASE_DIR/common/common_components_internal.sh $BASE_DIR 'common-libraries' $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET ; then
	echo “Common Rootfs: Operation $BUILD_TYPE/$COMPONENT_TARGET Success.”
	LOCAL_REGENERATE='--rebuild-all' 
else
	echo “Failed to build common rootfs to be used by host and guest. exit status: $?”
	exit 1
fi

if bash $BASE_DIR/host/build_host_internal.sh $BASE_DIR $LOCAL_REGENERATE $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET ; then
	echo “Host Rootfs: Operation $BUILD_TYPE/$COMPONENT_TARGET Success.”
	echo "Preparing to create docker image...."
	cd $BASE_DIR/build/containers
	if [ ! -e rootfs_host.ext4 ]; then
		echo "Cannot find rootfs_host.ext4 file. Please check the build...."
		exit 1
	fi

	if [[ "$(docker images -q intel_host 2> /dev/null)" != "" ]]; then
		docker rmi -f intel_host:latest
	fi
  
	if mount | grep intel_host > /dev/null; then
		sudo umount -l intel_host
	fi
	
	rm -rf intel_host
	mkdir intel_host
	sudo mount rootfs_host.ext4 intel_host
	sudo tar -C intel_host -c . | sudo docker import - intel_host
	sudo umount -l intel_host
	rm -rf intel_host 
else
	echo “Failed to build Host rootfs, exit status: $?”
	exit 1
fi

##########################Local Build State For Container##############################
LOCAL_REGENERATE=$COMPONENT_TARGET
LOCAL_UPDATE_CONTAINER='--false'
LOCAL_BUILD_TYPE=$BUILD_TYPE

if [[ "$COMPONENT_TARGET" == "--guest" ]]; then
	LOCAL_UPDATE_CONTAINER='--true'
fi

cd $BASE_DIR/

##########################Build Gamefast Image############################## 
if bash $BASE_DIR/rootfs/create_rootfs.sh $BASE_DIR 'game-fast' '--really-clean' ; then
	echo “Rootfs: Operation $BUILD_TYPE/$COMPONENT_TARGET Success.”    
	LOCAL_BUILD_TYPE='--clean'
	echo “Built rootfs for game fast container with default usersetup.”                                                           
else                                                                                                         
	echo “Failed to build Base rootfs for game fast container, exit status: $?”                                      
	exit 1                                                                                                     
fi

#########################Build Guest Image#####################################
if bash $BASE_DIR/rootfs/create_rootfs.sh $BASE_DIR 'guest' '--really-clean' '30000' ; then
	LOCAL_BUILD_TYPE="--clean"
	echo “Built Guest with default setup..”
else
	echo “Failed to build guest rootfs. exit status: $?”
	exit 1
fi

if bash common/common_components_internal.sh $BASE_DIR 'guest' $LOCAL_BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET; then
	echo “Built all common libraries to be used by Guest.”
else
	echo “Failed to build common libraries to be used by Guest. exit status: $?”
	exit 1
fi

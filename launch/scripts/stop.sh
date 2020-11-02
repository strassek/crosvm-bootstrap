#! /bin/bash

###################################################################
#Stop running VM
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

CHANNEL=${1}
TARGET=${2}

###############################################################################
##main()
###############################################################################
LOCAL_EXEC_DIRECTORY=/opt/$CHANNEL/$TARGET/x86_64/bin
LOCAL_INTEL_LIB_BASELINE=/opt/$CHANNEL/$TARGET/x86_64

LOCAL_LIBRARY_PATH=$LOCAL_INTEL_LIB_BASELINE/lib:$LOCAL_INTEL_LIB_BASELINE/lib/x86_64-linux-gnu:/lib:/lib/x86_64-linux-gnu

LD_LIBRARY_PATH=$LOCAL_LIBRARY_PATH  $LOCAL_EXEC_DIRECTORY/crosvm stop /images/crosvm.sock

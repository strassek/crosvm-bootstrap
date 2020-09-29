#! /bin/bash

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

CHANNEL=${1}
TARGET=${2}

LOCAL_EXEC_DIRECTORY=/opt/$CHANNEL/$TARGET/x86_64/bin
LOCAL_INTEL_LIB_BASELINE=/opt/$CHANNEL/$TARGET/x86_64

LOCAL_LIBRARY_PATH=$LOCAL_INTEL_LIB_BASELINE/lib:$LOCAL_INTEL_LIB_BASELINE/lib/x86_64-linux-gnu:/lib:/lib/x86_64-linux-gnu

LD_LIBRARY_PATH=$LOCAL_LIBRARY_PATH  $LOCAL_EXEC_DIRECTORY/crosvm stop /images/crosvm.sock

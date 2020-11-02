#! /bin/bash

# # Launch Sommelier Deamon

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

SERVICE='sommelier'

if pgrep -x "$SERVICE" >/dev/null
then
export SOMMELIER_SCALE=1.0
export SOMMELIER_GLAMOR=1
export SOMMELIER_DRM_DEVICE=/dev/dri/renderD128
export SOMMELIER_VIRTWL_DEVICE=/dev/wl0
else
LOCAL_USER=$(whoami)

mkdir -p /home/$LOCAL_USER/.env_conf
cp /intel/env/*.env /home/$LOCAL_USER/.env_conf/
mkdir -p /home/$LOCAL_USER/.config
cp /intel/env/weston.ini /home/$LOCAL_USER/.config/

cp /intel/env/.bashrc /home/$LOCAL_USER/
cp /intel/env/.bash_aliases /home/$LOCAL_USER/

cp /home/$LOCAL_USER/.env_conf/stable_release.env /home/$LOCAL_USER/.bash_env_settings
source /home/$LOCAL_USER/.bash_aliases

sommelier --glamor --drm-device=/dev/dri/renderD128 --master --no-exit-with-child &
echo "Launched Sommelier."
fi

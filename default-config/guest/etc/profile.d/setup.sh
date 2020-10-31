LOCAL_USER=$(whoami)
LOCAL_CONTAINER_NAME=game-fast-container
sudo mkdir -p /mnt/shared-host
sudo mount -t 9p shared-host /mnt/shared-host

if [[ -e /intel/shared-host ]]; then
  sudo unlink /intel/shared-host
fi

sudo ln -s /mnt/shared-host /intel/

mkdir -p /home/$LOCAL_USER/.env_conf
cp /intel/env/*.env /home/$LOCAL_USER/.env_conf/
cp /intel/env/weston.ini /home/$LOCAL_USER/

cd /intel/bin
sudo chmod +x *.sh
cd -
cd /intel/bin/container
sudo chmod +x *.sh
cd -

echo "Setting up environment........."
cp /home/$LOCAL_USER/.env_conf/stable_release.env /home/$LOCAL_USER/.bash_env_settings
source /home/test/.bashrc

if [[ $(docker ps -a -f "name=$LOCAL_CONTAINER_NAME" --format '{{.Names}}') != $LOCAL_CONTAINER_NAME ]]; then
	echo "Launching Container...."
	update-containers
	launch
fi

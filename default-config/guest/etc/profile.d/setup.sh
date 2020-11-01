# setup.sh
# Initial setup for Guest.

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

mkdir -p /home/$LOCAL_USER/.config
cp /intel/env/weston.ini /home/$LOCAL_USER/.config/

cp /intel/env/.bash_aliases /home/$LOCAL_USER/
cp /intel/env/.bashrc /home/$LOCAL_USER/

sudo cp /intel/env/resolv.conf /etc/

cd /intel/bin
sudo chmod +x *.sh
cd -

cd /intel/bin/container
sudo chmod +x *.sh
cd -

echo "Setting up environment........."
if [[ ! -e /intel/bin/update-containers ]]; then
	ln -s /intel/bin/setup-containers.sh /intel/bin/update-containers
fi

if [[ ! -e /intel/bin/launch-container ]]; then
	ln -s /intel/bin/launch-container.sh /intel/bin/launch-container
fi

if [[ ! -e /intel/bin/container/launch ]]; then
	sudo ln -s /intel/bin/container/app-launcher.sh /intel/bin/container/launch
fi

if [[ ! -e /intel/bin/container/launch-x ]]; then
	sudo ln -s /intel/bin/container/app-launcher-x.sh /intel/bin/container/launch-x
fi

if [[ ! -e /intel/bin/container/launch-h ]]; then
	sudo ln -s /intel/bin/container/headless.sh /intel/bin/container/launch-h
fi

if [[ ! -e /intel/bin/container/igt_run ]]; then
	sudo ln -s /intel/bin/container/igt_run.sh /intel/bin/container/igt_run
fi

sudo chown -R $LOCAL_USER:$LOCAL_USER /intel

cp /home/$LOCAL_USER/.env_conf/stable_release.env /home/$LOCAL_USER/.bash_env_settings
source /home/$LOCAL_USER/.bash_aliases

if [[ $(docker ps -a -f "name=$LOCAL_CONTAINER_NAME" --format '{{.Names}}') != $LOCAL_CONTAINER_NAME ]]; then
	echo "Launching Container...."
	update-containers
	launch-container
fi

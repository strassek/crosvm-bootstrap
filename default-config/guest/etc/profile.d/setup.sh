sudo mkdir -p /mnt/shared-host
sudo mount -t 9p shared-host /mnt/shared-host

if [[ -e /intel/shared-host ]]; then
  sudo unlink /intel/shared-host
fi

sudo ln -s /mnt/shared-host /intel/

cd /intel/bin
sudo chmod +x *.sh
cd -
cd /intel/bin/container
sudo chmod +x *.sh
cd -

echo "Setting up environment........."
LOCAL_USER=$(whoami)
cp /home/$LOCAL_USER/stable_release.env /home/$LOCAL_USER/.bash_env_settings
source /home/test/.bashrc
update-containers
launch &

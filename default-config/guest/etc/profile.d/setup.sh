sudo mkdir -p /mnt/shared-host
sudo mount -t 9p shared-host /mnt/shared-host
sudo ln -s /mnt/shared-host /intel/

cd /intel/bin
sudo chmod +x *.sh
cd -

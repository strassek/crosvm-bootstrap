#! /bin/bash

# user.sh
# Set up user account for the VM.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

LOCAL_UNAME=test
LOCAL_PASSWORD=test0000
LOCAL_uid=1000
LOCAL_gid=1000

adduser test
echo test:test0000 | chpasswd
echo "$LOCAL_UNAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$LOCAL_UNAME
chmod 0440 /etc/sudoers.d/$LOCAL_UNAME
chown test:test -R /home/$LOCAL_UNAME

echo "adding groups"
usermod -aG sudo,audio,video,input,render,lp $LOCAL_UNAME
#loginctl enable-linger $UNAME
echo "bash_aliases"

echo ". /home/$LOCAL_UNAME/.bash_env_settings" > /home/$LOCAL_UNAME/.bash_aliases
chmod 0440 /home/$LOCAL_UNAME/.bash_aliases

chown $uid:$gid -R /home/$LOCAL_UNAME
echo "Default user setup.."

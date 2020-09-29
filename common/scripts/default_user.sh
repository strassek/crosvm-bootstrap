#! /bin/bash

# default_user.sh
# Set up user account for Host Container & VM.

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

export uid=$LOCAL_uid gid=$LOCAL_gid
mkdir -p /home/$LOCAL_UNAME
echo "$LOCAL_UNAME:x:$uid:$gid:$LOCAL_UNAME,,,:/home/$LOCAL_UNAME:/bin/bash" >> /etc/passwd
echo "$LOCAL_UNAME:x:${uid}:" >> /etc/group
echo test:test0000 | chpasswd
echo "$LOCAL_UNAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$LOCAL_UNAME
chmod 0440 /etc/sudoers.d/$LOCAL_UNAME
chown $uid:$gid -R /home/$LOCAL_UNAME

echo "adding groups"
usermod -aG sudo,audio,video,input,render,lp $LOCAL_UNAME
#loginctl enable-linger $UNAME
echo "bash_aliases"

echo "if [ -f /home/$LOCAL_UNAME/.bash_env_settings ]; then" > /home/$LOCAL_UNAME/.bash_aliases
echo "  . /home/$LOCAL_UNAME/.bash_env_settings" >> /home/$LOCAL_UNAME/.bash_aliases
echo "fi"  >> /home/$LOCAL_UNAME/.bash_aliases

chmod 0664 /home/$LOCAL_UNAME/.bash_aliases

ls -a /etc/skel/ 

if [ -e /etc/skel/ ]; then
  cp -RvT /etc/skel /home/$LOCAL_UNAME
fi

ls -a /home/$LOCAL_UNAME 

chown $uid:$gid -R /home/$LOCAL_UNAME

echo "Default user setup.."

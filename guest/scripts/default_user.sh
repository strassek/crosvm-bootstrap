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

export uid=$LOCAL_uid gid=$LOCAL_gid
mkdir -p /home/developer
echo "$LOCAL_UNAME:x:$uid:$gid:$LOCAL_UNAME,,,:/home/$LOCAL_UNAME:/bin/bash" >> /etc/passwd
echo "$LOCAL_UNAME:x:${uid}:" >> /etc/group
echo $LOCAL_UNAME:$LOCAL_PASSWORD | chpasswd
echo "$LOCAL_UNAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$LOCAL_UNAME
chmod 0440 /etc/sudoers.d/$LOCAL_UNAME
chown $uid:$gid -R /home/$LOCAL_UNAME

echo "adding groups"
usermod -aG sudo,audio,video,input,render,lp $LOCAL_UNAME
#loginctl enable-linger $UNAME

cat > /home/$LOCAL_UNAME/.bash_aliases <<EOF
if [ -f /home/$LOCAL_UNAME/.bash_env_settings ]; then
    . /home/$LOCAL_UNAME/.bash_env_settings
fi
EOF

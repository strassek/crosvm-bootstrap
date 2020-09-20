#! /bin/bash

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

FORCE=0
if [[ $# -lt 2 ]]; then
	echo "Usage: configure-iptables.sh [--force] HOST_DEV VM_DEV" 1>&2
	echo "   ex: configure-iptables.sh wlan0 vmtap0" 1>&2
	exit 1
elif [[ $# -eq 3 ]]; then
	if [ $1 == "--force" ]; then
		FORCE=1
		shift
	fi
fi

if [[ $EUID -ne 0 ]]; then
	echo "You must be root!" 1>&2
	exit 1
fi

HOST=$1
GUEST=$2
EXISTING=`iptables -S | grep "\-i $GUEST \-o $HOST"`
if [[ ( $? == 0 && $FORCE != 1 ) ]]; then
	echo "Looks like your rules are already set up... aborting to be safe."
	echo "Rerun with --force to proceed anyway."
	exit 0
fi

iptables -t nat -A POSTROUTING -o $HOST -j MASQUERADE
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $GUEST -o $HOST -j ACCEPT

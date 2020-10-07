#! /bin/bash

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

HOST=$1
GUEST=$2
iptables -t nat -A POSTROUTING -o $HOST -j MASQUERADE
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $GUEST -o $HOST -j ACCEPT
echo "ip tables configured correctly."

#! /bin/bash

NICS=()
for n in /sys/class/net/* ; do
	NICS+=(`basename $n`)
done
DEFAULT_DEV=`cat /proc/net/route | cut -f 1,2 | grep "00000000" | head -1 | cut -f 1`

echo "Found devices:"
NUM=0
DEF_IDX=0
for n in ${NICS[@]} ; do
	let "NUM+=1"
	IP=`ip -4 a show dev $n | grep inet | cut -d'/' -f 1 | tr -dc '0-9.'`
	case $n in
	$DEFAULT_DEV)
		echo -e "$NUM)*\t$n ($IP)"
		let "DEF_IDX=NUM"
		;;
	*)
		echo -e "$NUM)\t$n ($IP)"
		;;
	esac
done

read -p "Select target device [$DEF_IDX]: " SEL
case $SEL in
[0-9])
	let "SEL-=1"
	DEV=${NICS[$SEL]}
	;;
*)
	DEV=${NICS[$DEF_IDX-1]}
	;;
esac

read -p "Specify the name of your tap device. [vmtap0]: " TAP_DEV
if [ -z "$TAP_DEV" ]; then
	TAP_DEV="vmtap0"
fi

#echo "{\"host\":\"$DEV\",\"tap\":\"$TAP_DEV\"}" > default-config/network.json
./scripts/configure-iptables.sh $DEV $TAP_DEV

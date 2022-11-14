#!/usr/bin/env bash
#set -x
set -euo pipefail

FILE=/tmp/lastConns.txt

if [ $# -lt 1 ]; then
	echo "Usage: $0 <TCP connections number threshold> [<hostname for messages>]"
	exit 0
fi

# Redirect stdout and stderr to syslog
exec 1> >(logger -s -t $(basename $0)) 2>&1

USAGE=$(cat /proc/net/sockstat | grep 'TCP:' | awk '{print $3}')

[[ -f ${FILE} ]] && THRESHOLD=`head -1 ${FILE}` || THRESHOLD=$1
[ $# -eq 2 ]  && hostname=$2 || hostname=$(hostname)

#echo "${THRESHOLD} ${USAGE}"
[ ${USAGE} -gt ${THRESHOLD} ] && /home/fkolodiazhnyi/bin/send2bot.sh "${hostname} Too many TCP connections ${USAGE}"

[ ${USAGE} -gt $1 ] && echo ${USAGE} > ${FILE} || echo $1 > ${FILE}

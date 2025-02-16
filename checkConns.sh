#!/usr/bin/env bash
#set -x
set -euo pipefail

FILE=/tmp/lastConns.txt
scriptDir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

if [ $# -lt 1 ]; then
	echo "Usage: $0 <TCP connections number threshold> [<hostname for messages>]"
	exit 0
fi

# Redirect stdout and stderr to syslog
exec 1> >(logger -s -t $(basename $0)) 2>&1

[ $# -eq 2 ]  && hostname=$2 || hostname=$(hostname)

function my_trap() {
        local lineno=$1
        local cmd=$(echo "$2" | tr -d '"')
        ${scriptDir}/send2bot.sh "$(basename $0): Failed at line ${lineno}: ${cmd}" ${hostname}
        exit 1
}

USAGE=$(cat /proc/net/sockstat | grep 'TCP:' | awk '{print $3}')

[[ -f ${FILE} ]] && THRESHOLD=`head -1 ${FILE}` || THRESHOLD=$1

#echo "${THRESHOLD} ${USAGE}"
[ ${USAGE} -gt ${THRESHOLD} ] && ${scriptDir}/send2bot.sh "${hostname} Too many TCP connections ${USAGE}"

[ ${USAGE} -gt $1 ] && echo ${USAGE} > ${FILE} || echo $1 > ${FILE}

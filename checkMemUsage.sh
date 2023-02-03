#!/usr/bin/env bash
#set -x
set -euo pipefail

FILE=/tmp/lastMemUsage.txt
scriptDir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

if [ $# -lt 1 ]; then
	echo "Usage: $0 <Free RAM % threshold> [<hostname for messages>]"
	exit 0
fi

# Redirect stdout and stderr to syslog
exec 1> >(logger -s -t $(basename $0)) 2>&1

USAGE=$(free | grep -E "^Mem:" | awk '{print 100*$4/$2}')

if [[ -f ${FILE} ]]; then
	THRESHOLD=$(head -1 ${FILE})
	IFS=' '
	read -a strarr <<< "${THRESHOLD}"
	if [ ${#strarr[*]} -eq 2 ]; then
		lastUsage=${strarr[0]}
		ALARM=${strarr[1]}
	elif [ ${#strarr[*]} -eq 1 ]; then
		lastUsage=${strarr[0]}
		ALARM=0
	else
		lastUsage=$1
		ALARM=0
	fi
else
	lastUsage=$1
	ALARM=0
fi
THRESHOLD=$1
[ $# -eq 2 ]  && hostname=$2 || hostname=$(hostname)

#echo "${THRESHOLD} ${lastUsage} ${ALARM} ${USAGE}"
if [[ ${USAGE} -lt ${THRESHOLD} && ${lastUsage} -lt ${THRESHOLD} && ${ALARM} -eq 0 ]]; then
	${scriptDir}/send2bot.sh "${hostname} High RAM Usage ALERT (${USAGE}%)"
	ALARM=1
fi
if [[ ${USAGE} -gt ${THRESHOLD} && ${ALARM} -eq 1 ]]; then
	${scriptDir}/send2bot.sh "${hostname} High RAM Usage OK (${USAGE}%)"
	ALARM=0
fi

echo "${USAGE} ${ALARM}" > ${FILE}

#!/usr/bin/env bash
#set -x
set -euo pipefail

FILE=/tmp/lastLA.txt
scriptDir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

if [ $# -lt 1 ]; then
	echo "Usage: $0 <la threshold> [<hostname for messages>]"
	exit 0
fi

# Redirect stdout and stderr to syslog
exec 1> >(logger -s -t $(basename $0)) 2>&1

USAGE=$(w | head -1 | sed 's/^.*load average: \(.*$\)/\1/' | awk '{ print $1 }' | sed 's/,//')
[ $# -eq 2 ]  && hostname=$2 || hostname=$(hostname)

function my_trap() {
        local lineno=$1
        local cmd=$(echo "$2" | tr -d '"')
        ${scriptDir}/send2bot.sh "$(basename $0): Failed at line ${lineno}: ${cmd}" ${hostname}
        exit 1
}

trap 'my_trap ${LINENO} "${BASH_COMMAND}"' ERR

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

# echo "${THRESHOLD} ${lastUsage} ${ALARM} ${USAGE}"
if (( $(echo "${USAGE} > ${THRESHOLD}" | bc -l) && $(echo "${lastUsage} > ${THRESHOLD}" | bc -l) && ${ALARM} == 0 )); then
	${scriptDir}/send2bot.sh "High LA ALERT (${USAGE}) $(ps aux | sort -nrk 3,3 | head -n 1)" "${hostname}" > /dev/null 2>&1
	ALARM=1
fi
if (( $(echo "${USAGE} <= ${THRESHOLD}" | bc -l) && ${ALARM} == 1 )); then
	${scriptDir}/send2bot.sh "High LA OK (${USAGE})" "${hostname}" > /dev/null 2>&1
	ALARM=0
fi

echo "${USAGE} ${ALARM}" > ${FILE}

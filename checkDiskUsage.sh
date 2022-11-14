#!/usr/bin/env bash
#set -x
set -euo pipefail

FILE=/tmp/lastDiskUsage.txt
arg2=""
counter=0

if [ $# -lt 2 ]; then
	echo "Usage: $0 <FS free space % threshold> <Filesystem(s)> [<hostname for messages>]"
	exit 0
fi

# Redirect stdout and stderr to syslog
exec 1> >(logger -s -t $(basename $0)) 2>&1

[[ -f ${FILE} ]] && THRESHOLD=`head -1 ${FILE}` || THRESHOLD=$1
[ $# -gt 2 ]  && hostname=$3 || hostname=$(hostname)

[[ -z "$(echo $2 | grep ',')" ]] && arg2=$(echo "$2" | tr -s ' ' | sed 's/ /|/g') || arg2=$(echo "$2" | tr -d ' ' | sed 's/,/|/g')
IFS='|'
read -a fileSystems <<< "${arg2}"
regex=$(echo "$arg2" | sed 's/\//\\\//g')

fsUsage=$(df -h | grep -E "${regex}")
while read -r line; do
	counter=$[${counter} + 1]
	USAGE=$[100-$(echo ${line} | awk '{print $5}' | tr -d '%')]
	if [ ${THRESHOLD} -gt ${USAGE} ]; then
		echo "Too low disk space: ${line}"
		/home/fkolodiazhnyi/bin/send2bot.sh "${hostname} Too low disk space: ${line}"
	fi
done <<< "${fsUsage}"

[ ${counter} -ne ${#fileSystems[@]} ] && echo "Not all Filesystems are founded: ${fileSystems[@]}"

# echo "${THRESHOLD} ${USAGE}"

[ ${USAGE} -lt $1 ] && echo ${USAGE} > ${FILE} || echo $1 > ${FILE}

#!/usr/bin/env bash
# set -x
set -euo pipefail

FILE=/tmp/lastLA.txt
scriptDir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

if [ $# -lt 1 ]; then
	echo "Usage: $0 <la threshold> [<hostname for messages>]"
	exit 0
fi

# Redirect stdout and stderr to syslog
exec 1> >(logger -s -t $(basename $0)) 2>&1

LA=$(w | head -1 | sed 's/^.*load average: \(.*$\)/\1/' | awk '{ print $1 }' | sed 's/,//')

[[ -f ${FILE} ]] && THRESHOLD=`head -1 ${FILE}` || THRESHOLD=$1
[ $# -eq 2 ]  && hostname=$2 || hostname=$(hostname)

# echo "${LA} ${THRESHOLD} $1"
(( $(echo "${LA} > ${THRESHOLD}" | bc -l) )) && ${scriptDir}/send2bot.sh "${hostname} la=${LA}"

(( $(echo "${LA} > $1" | bc -l) )) && echo ${LA} > ${FILE} || echo $1 > ${FILE}

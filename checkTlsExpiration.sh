#!/usr/bin/env bash
#set -x
set -euo pipefail

DAYS=30
scriptDir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source ${scriptDir}/sites.json

count=0
while true; do
	site=$(echo "${sites}" | jq ".[${count}]")
	[[ "${site}" == "null" ]] && break

	domain=$(echo "${site}" | jq -r "keys[]")
	url=$(echo "${site}" | jq -r ".\"${domain}\"")

#	echo "${domain}:${url}"
#	echo "${count}: ${site}"

	# Get certificate expiration date
	str=$(echo | openssl s_client -showcerts -servername ${domain} -connect ${url} 2>/dev/null | openssl x509 -inform pem -noout -text | sed -n "s/Not After ://p" | xargs)
	# Check if we don't get certificate

	signalDate=$(date -d "${str} -${DAYS} day" +%s)

	if [ ${signalDate} -lt $(date +%s) ]; then
		${scriptDir}/send2bot.sh "Certificate for ${domain} on ${url} expired at ${str}"
	fi

	count=$[${count}+1]
done
exit 0

str=$(echo | openssl s_client -showcerts -servername midot.com -connect git.midot.com:3000 2>/dev/null | openssl x509 -inform pem -noout -text | sed -n "s/Not After ://p" | xargs)
signalDate=$(date -d "${str} -1 month" +%s)
#echo "${str} - ${signalDate}"

[ ${signalDate} -gt $(date +%s) ] && exit 0

echo "Certificate near expiration date"

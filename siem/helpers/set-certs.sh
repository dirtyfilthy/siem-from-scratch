### This file should be sourced after SIEM_IP and SIEM_CN are set

if [ -z "$SIEM_IP" ] || [ -z "$SIEM_CN" ] || [ -z "$CONFIG_LOADED" ]; then

	echo "[!] Do not call this file directly, source it after SIEM_IP and SIEM_CN are set, and after siem/conf/siem/config.sh is sourced"
	echo "[!] exiting due to error..."
	exit 1

fi

CERTBASE="/vagrant/siem/certs/siem/elastic.${SIEM_CN}.${SIEM_IP}"
CERTDEFAULT_KEY=false
CERTDEFAULT_CRT=false
CERTDEFAULT_P12=false


if [ -z "$ELASTICSEARCH_KEY" ]; then
	ELASTICSEARCH_KEY="${CERTBASE}.key"
	CERTDEFAULT_KEY=true
fi

if [ -z "$ELASTICSEARCH_CRT" ]; then
	ELASTICSEARCH_CRT="${CERTBASE}.crt"
	CERTDEFAULT_CRT=true
fi

if [ -z "$ELASTICSEARCH_P12" ]; then
	ELASTICSEARCH_P12="${CERTBASE}.p12"
	CERTDEFAULT_P12=true
fi




#!/bin/sh

CURRDIR="$(cd "$(dirname "$0")"; pwd)"
BASEDIR="$(cd $CURRDIR/..; pwd)"
. $BASEDIR/conf/siem/config.sh

echo "[+] updating $BASEDIR/conf/siem/config.ps1"
VARIABLES="ELKVERSION SETUPLOCALBEATS ROOTCERT ELASTICSEARCH_CRT ELASTICSEARCH_KEY ELASTICSEARCH_P12 INSTALL_DASHBOARDS"
echo "# created from conf/siem/config.sh at $(date)" > $BASEDIR/conf/siem/config.ps1
for VARIABLE in $VARIABLES; do 
	eval VALUE="\$$VARIABLE"
	echo "\$${VARIABLE} = \"${VALUE}\"" >> $BASEDIR/conf/siem/config.ps1
done
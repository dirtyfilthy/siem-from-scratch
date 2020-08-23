#!/bin/sh
CURRDIR="$(cd "$(dirname "$0")"; pwd)"
BASEDIR="$(cd $CURRDIR/..; pwd)"
. $BASEDIR/conf/siem/config.sh
WGET_CMD="wget -q -m -nH --cut-dirs 100"

WGET() {
	URL=$1
	echo "[+] getting ${URL}"
	$WGET_CMD $URL
}


(
	# subshell
	cd $BASEDIR/resources

	# download prerequisites

	##
	## misc
	##

	# needed to fix logstash
	
	WGET https://raw.githubusercontent.com/bagder/ca-bundle/master/ca-bundle.crt

	###
	### elastic.co
	###

	WGET https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELKVERSION}-amd64.deb

	WGET https://artifacts.elastic.co/downloads/kibana/kibana-${ELKVERSION}-amd64.deb

	WGET https://artifacts.elastic.co/downloads/logstash/logstash-${ELKVERSION}.deb

	WGET https://artifacts.elastic.co/downloads/beats/auditbeat/auditbeat-${ELKVERSION}-amd64.deb

	WGET https://artifacts.elastic.co/downloads/beats/auditbeat/auditbeat-${ELKVERSION}-windows-x86_64.zip

	WGET https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-${ELKVERSION}-windows-x86_64.zip

	WGET https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${ELKVERSION}-amd64.deb

	WGET https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${ELKVERSION}-windows-x86_64.zip

	WGET https://artifacts.elastic.co/downloads/beats/packetbeat/packetbeat-${ELKVERSION}-amd64.deb

	WGET https://artifacts.elastic.co/downloads/beats/packetbeat/packetbeat-${ELKVERSION}-windows-x86_64.zip
	

	###
	### microsoft
	###

	WGET https://download.sysinternals.com/files/Sysmon.zip

	echo "[!] finished getting resources"
)
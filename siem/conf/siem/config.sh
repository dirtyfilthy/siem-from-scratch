### CONFIG

ELKVERSION=7.9.0
SETUPLOCALBEATS=false
ROOTCERT=/vagrant/siem/certs/myca/myCA.crt
INSTALL_DASHBOARDS=false

# leave blank for defaults

ELASTICSEARCH_P12=
ELASTICSEARCH_KEY=
ELASTICSEARCH_CRT=


## OTHER GLOBALS -- DON'T CHANGE


PASSOUT=/usr/share/elasticsearch/passwords.txt

DEFAULT_ROOTCERT=/vagrant/siem/certs/myca/myCA.crt

RESOURCE_PREREQUISITES="ca-bundle.crt elasticsearch-${ELKVERSION}-amd64.deb kibana-${ELKVERSION}-amd64.deb \
	logstash-${ELKVERSION}.deb auditbeat-${ELKVERSION}-amd64.deb auditbeat-${ELKVERSION}-windows-x86_64.zip \
	filebeat-${ELKVERSION}-amd64.deb filebeat-${ELKVERSION}-windows-x86_64.zip packetbeat-${ELKVERSION}-amd64.deb \
	packetbeat-${ELKVERSION}-windows-x86_64.zip winlogbeat-${ELKVERSION}-windows-x86_64.zip Sysmon.zip"



CONFIG_LOADED=ok
### CONFIG

ELKVERSION=7.9.0
SETUPLOCALBEATS=true
ROOTCERT=/vagrant/certs/myca/myCA.crt
ELASTICSEARCH_P12=/vagrant/certs/siem/elastic-certificates.p12
ELASTICSEARCH_KEY=/vagrant/certs/siem/elastic-certificates.key
ELASTICSEARCH_CRT=/vagrant/certs/siem/elastic-certificates.crt

## OTHER GLOBALS -- DON'T CHANGE

PASSOUT=/usr/share/elasticsearch/passwords.txt
DEFAULT_ROOTCERT=/vagrant/certs/myca/myCA.crt
DEFAULT_ELASTICSEARCH_P12=/vagrant/certs/siem/elastic-certificates.p12
DEFAULT_ELASTICSEARCH_KEY=/vagrant/certs/siem/elastic-certificates.key
DEFAULT_ELASTICSEARCH_CRT=/vagrant/certs/siem/elastic-certificates.crt
RESOURCE_PREREQUISITES="ca-bundle.crt elasticsearch-${ELKVERSION}-amd64.deb kibana-${ELKVERSION}-amd64.deb \
	logstash-${ELKVERSION}.deb auditbeat-${ELKVERSION}-amd64.deb filebeat-${ELKVERSION}-amd64.deb \
	packetbeat-${ELKVERSION}-amd64.deb winlogbeat-${ELKVERSION}-windows-x86_64.zip"  
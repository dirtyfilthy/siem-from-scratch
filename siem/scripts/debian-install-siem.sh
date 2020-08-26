#!/bin/sh



### PARAMS

SIEM_CN=$1
SIEM_IP=$2

### CONFIG

. /vagrant/siem/conf/siem/config.sh
. /vagrant/siem/helpers/set-certs.sh

### FUNCTIONS

get_userpass(){
	PASSFILE=$1
	USER=$2
	cat $PASSFILE | grep "PASSWORD $USER" | cut -f 2 -d "=" | tr -d " "
}

check_kibana(){
	if curl -s -I -u elastic:Password1 -X GET https://$SIEM_IP:5601/api/features | grep -q "HTTP/1.1 200 OK"; then
		return 0
	else
		return 1
	fi
}


wait_for_kibana(){
	TIMEOUT=$1
	STARTTIME=$(date +%s)
	echo "[?] waiting for kibana to start (normally under 60 seconds)"
	while ! check_kibana; do
		CURRENTTIME=$(date +%s)
		ELAPSED=$(expr $CURRENTTIME - $STARTTIME)
		if [ $ELAPSED -gt $TIMEOUT ]; then
			return 1
		fi
		echo "[+] waited $ELAPSED seconds, sleeping"
		sleep 1
	done
	return 0

}

echo " "
echo "################################################"
echo "#                                               "
echo "# PREFLIGHT "                        
echo "#                                               "
echo "################################################"
echo " "

echo "[?] checking for arguments..."

if [ -z "$SIEM_IP" ] || [ -z "$SIEM_CN" ]; then
	echo "[!] ERROR: this provisioning script requires both the SIEM IP and SIEM hostname arguments to function!"
	echo "[!] either pass the \"args\" parameter with the SIEM_IP and SIEM_CN variables or directly"
	echo "[!] with \"hostname\" and \"1.2.3.4\" like this:"
	echo "[!] "
	echo "[!] cfg.vm.provision \"shell\", path: \"siem/scripts/debian-install-siem.sh\", args: [SIEM_CN, SIEM_IP]"
	echo "[!] "
	echo "[!] or"
	echo "[!] "
	echo "[!] cfg.vm.provision \"shell\", path: \"siem/scripts/debian-install-siem-sh\", args: [\"hostname\", \"1.2.3.4\"]"
	echo "[!] "
	echo "[!] exiting due to error!"
	exit 1
fi

echo "[?] running with domain: ${SIEM_CN}, IP: ${SIEM_IP}"
echo "[?] "

VARIABLES="ELKVERSION ROOTCERT ELASTICSEARCH_P12 ELASTICSEARCH_KEY ELASTICSEARCH_CRT SETUPLOCALBEATS INSTALL_DASHBOARDS"
echo "[?] settings: "
echo "[?] "
for VARIABLE in $VARIABLES; do
	eval VALUE="\$$VARIABLE"
	printf "[?] %-20s = %s\n" $VARIABLE $VALUE
done

### SCRIPT

echo " "
echo "################################################"
echo "#                                               "
echo "# INSTALL ELASTICSEARCH "                        
echo "#                                               "
echo "################################################"
echo " "
echo [+] install elasticsearch-${ELKVERSION}-amd64.deb
dpkg -i /vagrant/siem/resources/elasticsearch-${ELKVERSION}-amd64.deb

echo [+] copy elasticsearch configuration
cp /vagrant/siem/conf/elasticsearch/* /etc/elasticsearch

echo [+] start elastic service
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service

echo [+] start elasticsearch platinum trial
curl -s -X POST "localhost:9200/_license/start_trial?acknowledge=true&pretty"


echo [+] stop elasticsearch
service elasticsearch stop


echo [+] set network host to $SIEM_IP
sed -i "s/network.host: 127.0.0.1/network.host: ${SIEM_IP}/" /etc/elasticsearch/elasticsearch.yml

echo [+] override default memory locking
mkdir /etc/systemd/system/elasticsearch.service.d
echo "[Service]" >> /etc/systemd/system/elasticsearch.service.d/override.conf
echo "LimitMEMLOCK=infinity" >> /etc/systemd/system/elasticsearch.service.d/override.conf
systemctl daemon-reload

echo [+] create cluster.initial_master_nodes
echo >> /etc/elasticsearch/elasticsearch.yml
echo "cluster.initial_master_nodes: [\"siem1\"]" >> /etc/elasticsearch/elasticsearch.yml

echo [+] setting up xpack...

echo >> /etc/elasticsearch/elasticsearch.yml
echo "######## xpack settings follow #######" >> /etc/elasticsearch/elasticsearch.yml

echo [+] enable xpack.security
echo "xpack.security.enabled: true" >> /etc/elasticsearch/elasticsearch.yml

echo [+] enable elasticsearch TLS
cp $ELASTICSEARCH_P12 /etc/elasticsearch/elastic-certificates.p12
cp $ELASTICSEARCH_KEY /etc/elasticsearch/elastic-certificates.key
cp $ELASTICSEARCH_CRT  /etc/elasticsearch/elastic-certificates.crt
cp $ROOTCERT /etc/elasticsearch/myCA.crt
chmod +r /etc/elasticsearch/myCA.crt
chmod +r /etc/elasticsearch/elastic-certificates.*
echo "xpack.security.transport.ssl.verification_mode: certificate " >> /etc/elasticsearch/elasticsearch.yml
echo "xpack.security.transport.ssl.keystore.path: elastic-certificates.p12" >> /etc/elasticsearch/elasticsearch.yml
echo "xpack.security.transport.ssl.enabled: true" >> /etc/elasticsearch/elasticsearch.yml

echo [+] enable elasticsearch HTTP TLS

echo "xpack.security.http.ssl.enabled: true" >> /etc/elasticsearch/elasticsearch.yml
echo "xpack.security.http.ssl.certificate: elastic-certificates.crt" >>  /etc/elasticsearch/elasticsearch.yml
echo "xpack.security.http.ssl.key: elastic-certificates.key" >> /etc/elasticsearch/elasticsearch.yml
#echo "xpack.security.http.ssl.certificate_authorities: [ \"myCA.crt\" ]" >> /etc/elasticsearch/elasticsearch.yml

echo [+] restart elasticsearch
service elasticsearch restart

echo [+] creating auto passwords
echo [?] passwords will be saved to $PASSOUT

yes | /usr/share/elasticsearch/bin/elasticsearch-setup-passwords auto | tee $PASSOUT

echo "[+] resetting elastic password (l: elastic/Password1)"

ELASTICPW=$(get_userpass $PASSOUT elastic)
curl -k -s --user elastic:$ELASTICPW -X POST "https://$SIEM_IP:9200/_security/user/elastic/_password?pretty" -H 'Content-Type: application/json' -d'
{
  "password" : "Password1"
}
'
echo " "
echo "################################################"
echo "#                                               "
echo "# INSTALL KIBANA "                        
echo "#                                               "
echo "################################################"
echo " "
echo [+] install kibana-${ELKVERSION}-amd64.deb

dpkg -i /vagrant/siem/resources/kibana-${ELKVERSION}-amd64.deb

echo [+] copy config
cp -r /vagrant/siem/conf/kibana/* /etc/kibana

echo [+] create kibana /var/log directory

mkdir /var/log/kibana
chown kibana /var/log/kibana

echo [+] create kibana /var/run directory

echo [+] copy $ROOTCERT to /etc/kibana/myCA.crt
cp $ROOTCERT /etc/kibana/myCA.crt
chown kibana /etc/kibana/myCA.crt

mkdir /var/run/kibana
chown kibana /var/run/kibana

echo [+] adding kibana_system password to kibana.yml
KIBANAPW=$(get_userpass $PASSOUT kibana_system)
echo "elasticsearch.username: \"kibana_system\"" >> /etc/kibana/kibana.yml
echo "elasticsearch.password: \"$KIBANAPW\"" >> /etc/kibana/kibana.yml

echo [+] enable kibana TLS
cp $ELASTICSEARCH_P12 /usr/share/elasticsearch/elastic-certificates.p12
chmod +r /usr/share/elasticsearch/elastic-certificates.p12
echo 'server.ssl.keystore.path: "/usr/share/elasticsearch/elastic-certificates.p12"' >> /etc/kibana/kibana.yml
echo 'server.ssl.enabled: true' >> /etc/kibana/kibana.yml
echo 'server.ssl.keystore.password: ""' >> /etc/kibana/kibana.yml

echo [+] add elasticsearch trusted cert to kibana.ymnl
echo 'elasticsearch.ssl.certificateAuthorities: [ "/etc/kibana/myCA.crt" ]' >> /etc/kibana/kibana.yml

echo [+] reconfigure kibana to use elasticsearch address https://$SIEM_IP:9200/

sed -i "s/http:\\/\\/localhost:9200/https:\\/\\/${SIEM_IP}:9200/g" /etc/kibana/kibana.yml

echo [+] creating xpack.encryptedSavedObjects.encryptionKey
ENCRYPTIONKEY=$(head -c 32 /dev/urandom | md5sum | cut -f 1 -d " ")
echo "[?] created xpack.encryptedSavedObjects.encryptionKey $ENCRYPTIONKEY"
echo "xpack.encryptedSavedObjects.encryptionKey: \"${ENCRYPTIONKEY}\"" >> /etc/kibana/kibana.yml

echo [+] configure auth providers
echo "xpack.security.authProviders: [token, basic]" >> /etc/kibana/kibana.yml

echo [+] start kibana service
systemctl daemon-reload
systemctl enable kibana.service
systemctl start kibana.service

KIBANA_TIMEOUT=120
if ! wait_for_kibana $KIBANA_TIMEOUT; then
	echo "[!] ERROR: waited $KIBANA_TIMEOUT seconds and kibana still hasn't started"
	echo "[!] exiting... "
	exit 1
fi

echo " " 
echo "################################################"
echo "#                                               "
echo "# INSTALL LOGSTASH "                        
echo "#                                               "
echo "################################################"
echo " "
echo [+] install logstash-${ELKVERSION}.deb

dpkg -i /vagrant/siem/resources/logstash-${ELKVERSION}.deb

echo [+] copy logstash config
cp -r /vagrant/siem/conf/logstash/*	/etc/logstash/

echo [+] fix missing logstash ca-bundle.crt
mkdir -p /etc/pki/tls/certs/
cp /vagrant/siem/resources/ca-bundle.crt /etc/pki/tls/certs/

echo [+] create logstash_writer role
curl -s --user elastic:Password1 -X POST "https://$SIEM_IP:9200/_xpack/security/role/logstash_writer" -H 'Content-Type: application/json' -d'
{
  "cluster": ["manage_index_templates", "monitor", "manage_ilm"], 
  "indices": [
    {
      "names": [ "logstash-*", "auditbeat-*", "winlogbeat-*", "packetbeat-*", "filebeat-*"], 
      "privileges": ["write","create","delete","create_index","manage","manage_ilm"]  
    }
  ]
}'

echo [+] create logstash_internal user
curl -k -s --user elastic:Password1 -X POST "https://$SIEM_IP:9200/_xpack/security/user/logstash_internal" -H 'Content-Type: application/json' -d'
{
  "password" : "Password1", 
  "roles" : [ "logstash_writer"],
  "full_name" : "Internal Logstash User"
}'

echo [+] updating /etc/logstash/conf.d/output-elasticsearch.conf with logstash_internal credentials
sed -i 's/#usernameNOEDIT/user => "logstash_internal"/;s/#passwordNOEDIT/password => "Password1"/;' /etc/logstash/conf.d/output-elasticsearch.conf

echo "[+] updating /etc/logstash/conf.d/output-elasticsearch.conf with https://$SIEM_IP:9200/"
cp $ROOTCERT /etc/logstash/myCA.crt
chown logstash /etc/logstash/myCA.crt
sed -i "s/localhost:9200/https:\\/\\/${SIEM_IP}:9200/g" /etc/logstash/conf.d/output-elasticsearch.conf
sed -i "s/#sslNOEDIT/ssl => true/" /etc/logstash/conf.d/output-elasticsearch.conf
sed -i 's/#cacertNOEDIT/cacert => "\/etc\/logstash\/myCA.crt"/' /etc/logstash/conf.d/output-elasticsearch.conf
#echo [+] adding logstash_system password to logstash.yml
#LOGSTASHPW=$(get_userpass $PASSOUT logstash_system)
#echo "xpack.monitoring.elasticsearch.username: \"logstash_system\"" >> /etc/logstash/logstash.yml
#echo "xpack.monitoring.elasticsearch.password: \"$LOGSTASHPW\"" >> /etc/logstash/logstash.yml

echo [+] start logstash service
systemctl daemon-reload
systemctl enable logstash.service
systemctl start logstash.service

echo " "
echo "################################################"
echo "#                                               "
echo "# INSTALL FILEBEAT "                        
echo "#                                               "
echo "################################################"
echo " "
echo [+] install filebeat-${ELKVERSION}-amd64.deb

dpkg -i /vagrant/siem/resources/filebeat-${ELKVERSION}-amd64.deb

echo [+] copy filebeat config
cp -r /vagrant/siem/conf/filebeat/*	/etc/filebeat/

echo [+] setup filebeat template
filebeat setup --index-management -E output.logstash.enabled=false -E "output.elasticsearch.hosts=[\"https://$SIEM_IP:9200\"]" \
	-E 'output.elasticsearch.username="elastic"' -E 'output.elasticsearch.password="Password1"' -E "setup.ilm.overwrite=true"

if [ "$INSTALL_DASHBOARDS" = "true" ]; then
	echo [+] setup filebeat dashboards
	filebeat setup --dashboards -E output.logstash.enabled=false -E "output.elasticsearch.hosts=[\"https://$SIEM_IP:9200\"]" \
		-E 'output.elasticsearch.username="elastic"' -E 'output.elasticsearch.password="Password1"' \
		-E "setup.kibana.host=\"https://$SIEM_IP:5601\""
fi

echo " "
echo "################################################"
echo "#                                               "
echo "# INSTALL PACKETBEAT "                        
echo "#                                               "
echo "################################################"
echo " "
echo [+] install packetbeat-${ELKVERSION}-amd64.deb

dpkg -i /vagrant/siem/resources/packetbeat-${ELKVERSION}-amd64.deb

echo [+] copy packetbeat config
cp -r /vagrant/siem/conf/packetbeat/*	/etc/packetbeat/

echo [+] setup packetbeat template
packetbeat setup --index-management -E output.logstash.enabled=false -E "output.elasticsearch.hosts=[\"https://$SIEM_IP:9200\"]" \
	-E 'output.elasticsearch.username="elastic"' -E 'output.elasticsearch.password="Password1"' -E "setup.ilm.overwrite=true"

if [ "$INSTALL_DASHBOARDS" = "true" ]; then
	echo [+] setup packetbeat dashboards
	packetbeat setup --dashboards -E output.logstash.enabled=false -E "output.elasticsearch.hosts=[\"https://$SIEM_IP:9200\"]" \
		-E 'output.elasticsearch.username="elastic"' -E 'output.elasticsearch.password="Password1"' \
		-E "setup.kibana.host=\"https://$SIEM_IP:5601\""
fi

echo " "
echo "################################################"
echo "#                                               "
echo "# INSTALL WINLOGBEAT "                        
echo "#                                               "
echo "################################################"
echo " "
WINLOGBEAT=winlogbeat-${ELKVERSION}-windows-x86_64
WINLOGZIP=${WINLOGBEAT}.zip

if ! [ -f /vagrant/siem/conf/winlogbeat/winlogbeat-${ELKVERSION}.template.json ]; then
	echo "[!] /vagrant/siem/conf/winlogbeat/winlogbeat-${ELKVERSION}.template.json does not exist"
	echo "[!] you need to generate it by running:"
	echo "[!] .\winlogbeat.exe export template --es.version ${ELKVERSION} | Out-File -Encoding UTF8 /vagrant/siem/conf/winlogbeat/winlogbeat-${ELKVERSION}.template.json"
	echo "[!] from powershell on a windows machine from the winlogbeat installation directory"
	exit 1
fi

echo [+] install index template

curl -s -u "elastic:Password1" -X PUT "https://${SIEM_IP}:9200/_template/winlogbeat-${ELKVERSION}"  -H 'Content-Type: application/json' \
	--data-binary @/vagrant/siem/conf/winlogbeat/winlogbeat-${ELKVERSION}.template.json

echo [+] create index alias 

curl -s -u "elastic:Password1" -X PUT "https://${SIEM_IP}:9200/%3Cwinlogbeat-${ELKVERSION}-%7Bnow%2Fd%7D-000001%3E"  \
	-H 'Content-Type: application/json' -d "{\"aliases\":{\"winlogbeat-${ELKVERSION}\":{\"is_write_index\":true}}}"

if [ "$INSTALL_DASHBOARDS" = "true" ]; then


	echo [+] copy $WINLOGZIP to /tmp
	cp /vagrant/siem/resources/$WINLOGZIP /tmp

	echo [+] installing unzip
	apt-get -y install unzip

	echo [+] unzipping $WINLOGZIP

	(cd /tmp && unzip $WINLOGZIP)

	echo [+] setup winlogbeat dashboards

	(
		cd /tmp/$WINLOGBEAT

		auditbeat setup --dashboards -E output.logstash.enabled=false -E "output.elasticsearch.hosts=[\"https://$SIEM_IP:9200\"]" \
			-E 'output.elasticsearch.username="elastic"' -E 'output.elasticsearch.password="Password1"' \
			-E "setup.kibana.host=\"https://$SIEM_IP:5601\""  -E setup.dashboards.directory=kibana

	)
fi

echo " "
echo "################################################"
echo "#                                               "
echo "# INSTALL AUDITBEAT "                        
echo "#                                               "
echo "################################################"
echo " "
echo [+] install auditbeat-${ELKVERSION}-amd64.deb

dpkg -i /vagrant/siem/resources/auditbeat-${ELKVERSION}-amd64.deb

echo [+] copy auditbeat config
cp -r /vagrant/siem/conf/auditbeat/*	/etc/auditbeat/

echo [+] setup auditbeat template
auditbeat setup --index-management -E output.logstash.enabled=false -E "output.elasticsearch.hosts=[\"https://$SIEM_IP:9200\"]" \
	-E 'output.elasticsearch.username="elastic"' -E 'output.elasticsearch.password="Password1"' -E "setup.ilm.overwrite=true"


if [ "$INSTALL_DASHBOARDS" = "true" ]; then
	echo [+] setup auditbeat dashboards
	auditbeat setup --dashboards -E output.logstash.enabled=false -E "output.elasticsearch.hosts=[\"https://$SIEM_IP:9200\"]" \
		-E 'output.elasticsearch.username="elastic"' -E 'output.elasticsearch.password="Password1"' \
		-E "setup.kibana.host=\"https://$SIEM_IP:5601\""
fi

echo " "
echo "################################################"
echo "#                                               "
echo "# CONFIGURE SIEM "                        
echo "#                                               "
echo "################################################"
echo " "
echo "[+] install 'jq' json tool"
apt-get -y install jq

echo [+] create siem signal index
curl -s -u "elastic:Password1" -X POST "https://${SIEM_IP}:5601/api/detection_engine/index" -H 'kbn-xsrf: true'
#curl -u "elastic:Password1" -X POST "https://$SIEM_IP:5601/s/siem/api/detection_engine/index" -H 'kbn-xsrf: true'

echo [+] load prepackaged siem detection rules
curl -s -u "elastic:Password1" -X PUT "https://${SIEM_IP}:5601/api/detection_engine/rules/prepackaged" -H 'kbn-xsrf: true'

echo [+] activate all rules

RULEIDS=$(curl -s -u "elastic:Password1" -X GET "https://${SIEM_IP}:5601/api/detection_engine/rules/_find?per_page=1000" \
                -H 'kbn-xsrf: true' | jq '.data | .[] | select(.enabled=false) | .id' | tr -d '"')

CURLREQ=$(mktemp)
echo '[' > $CURLREQ
COMMA=""
for RULEID in $RULEIDS; do
	echo "${COMMA}{\"id\":\"${RULEID}\", \"enabled\":true}" >> $CURLREQ
	COMMA=","
done
echo ']' >> $CURLREQ

curl -s -u "elastic:Password1" -X PATCH "https://${SIEM_IP}:5601/api/detection_engine/rules/_bulk_update" \
	--data-binary @${CURLREQ}  -H  'kbn-xsrf: true' -H 'Content-Type: application/json' > /dev/null

rm $CURLREQ

echo [+] set SIEM as homepage

curl -s -u "elastic:Password1" -X POST "https://${SIEM_IP}:5601/api/kibana/settings" \
	-d '{"changes":{"defaultRoute":"/app/security/overview"}}' -H 'kbn-xsrf: true' -H 'Content-Type: application/json'

echo " "
echo "################################################"
echo "#                                               "
echo "# POST SETUP "                        
echo "#                                               "
echo "################################################"
echo " "
echo "[?] starting local beats services... ${SETUPLOCALBEATS}"
echo
if [ "$SETUPLOCALBEATS" = "true" ]; then

	echo [+] start auditbeat service
	service auditbeat start

	echo [+] start filebeat service
	service filebeat start

	echo [+] start packetbeat service
	service packetbeat start

fi
echo 
echo "[!] DONE! "
echo "[!] "
echo "[!] You can now login to the SIEM dashboard:"
echo "[!] "
echo "[!] >>> Dashboard:   https://${SIEM_IP}:5601/" 
echo "[!] >>> Username:    elastic"
echo "[!] >>> Password:    Password1"
echo "[!] "
echo "[!] Happy Hunting!"
echo " "
echo " "
echo " "















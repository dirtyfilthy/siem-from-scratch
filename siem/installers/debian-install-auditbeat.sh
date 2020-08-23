SIEM_IP=$1

. /vagrant/siem/conf/siem/config.sh

if [ -z "$SIEM_IP"]; then
	echo "[!] ERROR: this provisioning script requires the SIEM IP as an argument to function!"
	echo "[!] Edit your VagrantFile shell provisioning line to include either the 'args' parameter"
	echo "[!] with either the SIEM_IP variable or quoted \"1.2.3.4\" direct IP, like this:"
	echo "[!] "
	echo "[!] cfg.vm.provision \"shell\", path: \"siem/installers/debian-install-auditbeat.sh\", args: SIEM_IP"
	echo "[!]"
	echo "[!] or"
	echo "[!]"
	echo "[!] cfg.vm.provision \"shell\", path: \"siem/installers/debian-install-auditbeat.sh\", args: \"1.2.3.4\""
	echo "[!]"
	echo "[!] exiting due to error"
	exit 1
fi


echo [+] install auditbeat-${ELKVERSION}-amd64.deb

dpkg -i /vagrant/siem/resources/auditbeat-${ELKVERSION}-amd64.deb

echo [+] configure auditbeat

cp /vagrant/siem/conf/auditbeat/auditbeat.yml /etc/auditbeat 
sed -i "s/localhost/${SIEM_IP}/g" /etc/auditbeat/auditbeat.yml
mkdir -p /var/log/auditbeat

echo [+] starting auditbeat
service auditbeat start

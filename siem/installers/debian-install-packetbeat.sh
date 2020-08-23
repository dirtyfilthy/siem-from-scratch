SIEM_IP=$1

. /vagrant/siem/conf/siem/config.sh

if [ -z "$SIEM_IP"]; then
	echo "[!] ERROR: this provisioning script requires the SIEM IP as an argument to function!"
	echo "[!] Edit your VagrantFile shell provisioning line to include either the 'args' parameter"
	echo "[!] with either the SIEM_IP variable or quoted \"1.2.3.4\" direct IP, like this:"
	echo "[!] "
	echo "[!] cfg.vm.provision \"shell\", path: \"siem/installers/debian-install-packetbeat.sh\", args: SIEM_IP"
	echo "[!]"
	echo "[!] or"
	echo "[!]"
	echo "[!] cfg.vm.provision \"shell\", path: \"siem/installers/debian-install-packetbeat.sh\", args: \"1.2.3.4\""
	echo "[!]"
	echo "[!] exiting due to error"
	exit 1
fi

echo [+] install packetbeat-${ELKVERSION}-amd64.deb

dpkg -i /vagrant/siem/resources/packetbeat-${ELKVERSION}-amd64.deb

echo [+] configure packetbeat

cp /vagrant/siem/conf/packetbeat/packetbeat.yml /etc/packetbeat 
sed -i "s/localhost/${SIEM_IP}/g" /etc/packetbeat/packetbeat.yml
mkdir -p /var/log/packetbeat

echo [+] starting packetbeat
service packetbeat start

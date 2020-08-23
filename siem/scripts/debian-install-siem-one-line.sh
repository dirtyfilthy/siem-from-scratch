#!/bin/sh

### CONFIG

. /vagrant/siem/conf/siem/config.sh

### PARAMS

SIEM_CN=$1
SIEM_IP=$2

# every great tool starts life as a figlet logo

/vagrant/siem/helpers/logo.sh

if [ -z "$SIEM_IP" ] || [ -z "$SIEM_CN" ]; then
	echo "[!] ERROR: this provisioning script requires both the SIEM IP and SIEM hostname arguments to function!"
	echo "[!] either pass the \"args\" parameter with the SIEM_IP and SIEM_CN variables or directly"
	echo "[!] with \"hostname\" and \"1.2.3.4\" like this:"
	echo "[!] "
	echo "[!] cfg.vm.provision \"shell\", path: \"siem/scripts/debian-install-siem-one-line.sh\", args: [SIEM_CN, SIEM_IP]"
	echo "[!] "
	echo "[!] or"
	echo "[!] "
	echo "[!] cfg.vm.provision \"shell\", path: \"siem/scripts/debian-install-siem-one-line.sh\", args: [\"hostname\", \"1.2.3.4\"]"
	echo "[!] "
	echo "[!] exiting due to error!"
	exit 1
fi

/vagrant/siem/scripts/global-update-powershell-config.sh
/vagrant/siem/scripts/debian-upgrade.sh
/vagrant/siem/scripts/debian-install-java11.sh
/vagrant/siem/scripts/debian-check-siem-resources.sh
/vagrant/siem/scripts/debian-check-siem-certs.sh $SIEM_CN $SIEM_IP
/vagrant/siem/scripts/debian-install-siem.sh $SIEM_CN $SIEM_IP
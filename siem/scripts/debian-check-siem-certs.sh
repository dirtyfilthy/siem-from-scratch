#!/bin/sh

SIEM_CN=$1
SIEM_IP=$2

. /vagrant/siem/conf/siem/config.sh

if [ -z "$SIEM_IP" ] || [ -z "$SIEM_CN" ]; then
	echo "[!] ERROR: this provisioning script requires both the SIEM IP and SIEM hostname arguments to function!"
	echo "[!] either pass the \"args\" parameter with the SIEM_IP and SIEM_CN variables or directly"
	echo "[!] with \"hostname\" and \"1.2.3.4\" like this:"
	echo "[!] "
	echo "[!] cfg.vm.provision \"shell\", path: \"siem/scripts/debian-check-siem-certs.sh\", args: [SIEM_CN, SIEM_IP]"
	echo "[!] "
	echo "[!] or"
	echo "[!] "
	echo "[!] cfg.vm.provision \"shell\", path: \"siem/scripts/debian-check-siem-certss.sh\", args: [\"hostname\", \"1.2.3.4\"]"
	echo "[!] "
	echo "[!] exiting due to error!"
	exit 1
fi

echo " "
echo "################################################"
echo "#                                               "
echo "# CERT CHECK "                        
echo "#                                               "
echo "################################################"
echo " "

echo "[+] ensuring openssl is installed"

apt-get -y install openssl

echo "[+] checking certs..."

if [ "$ROOTCERT" != "$DEFAULT_ROOTCERT" ] && ! [ -f "$ROOTCERT" ]; then
	echo "[!] ERROR: custom rootcert defined but file $ROOTCERT does not exist"
	exit 1
fi

if [ "$ROOTCERT" != "$DEFAULT_ROOTCERT" ] && ! [ -f "$ELASTICSEARCH_P12" ]; then
	echo "[!] ERROR: custom rootcert defined but file $ELASTICSEARCH_P12 does not exist"
	exit 1
fi

if [ "$ROOTCERT" != "$DEFAULT_ROOTCERT" ] && ! [ -f "$ELASTICSEARCH_KEY" ]; then
	echo "[!] ERROR: custom rootcert defined but file $ELASTICSEARCH_KEY does not exist"
	exit 1
fi

if [ "$ROOTCERT" != "$DEFAULT_ROOTCERT" ] && ! [ -f "$ELASTICSEARCH_CRT" ]; then
	echo "[!] ERROR: custom rootcert defined but file $ELASTICSEARCH_CRT does not exist"
	exit 1
fi

if [ "$ELASTICSEARCH_KEY" != "$DEFAULT_ELASTICSEARCH_KEY" ] && ! [ -f "$ELASTICSEARCH_KEY" ]; then
	echo "[!] ERROR: custom elasticsearch .key defined but file $ELASTICSEARCH_CRT does not exist"
	exit 1
fi

if [ "$ELASTICSEARCH_CRT" != "$DEFAULT_ELASTICSEARCH_CRT" ] && ! [ -f "$ELASTICSEARCH_CRT" ]; then
	echo "[!] ERROR: custom elasticsearch .crt defined but file $ELASTICSEARCH_CRT does not exist"
	exit 1
fi

if [ "$ELASTICSEARCH_P12" != "$DEFAULT_ELASTICSEARCH_P12" ] && ! [ -f "$ELASTICSEARCH_P12" ]; then
	echo "[!] ERROR: custom elasticsearch .p12 defined but file $ELASTICSEARCH_P12 does not exist"
	exit 1
fi

if [ "$ROOTCERT" = "$DEFAULT_ROOTCERT" ] && ! [ -f "$ROOTCERT" ]; then
	echo "[!] default rootcert $ROOTCERT does not exist, creating"
	/vagrant/siem/helpers/make-ca.sh
fi

if [ "$ELASTICSEARCH_P12" = "$DEFAULT_ELASTICSEARCH_P12" ] && ! [ -f "$ELASTICSEARCH_P12" ]; then
	echo "[!] missing default elastic-certificates.p12, generating..."
	echo [+] creating certs/siem/elastic-certificates.p12
	/vagrant/siem/helpers/create-lab-cert.sh $SIEM_CN $SIEM_IP /vagrant/siem/certs/siem/elastic-certificates
fi

/vagrant/siem/scripts/debian-install-root-cert.sh $ROOTCERT
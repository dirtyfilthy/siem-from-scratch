#!/bin/sh

### CONFIG

. /vagrant/siem/conf/siem/config.sh

### PARAMS

SIEM_CN=$1
SIEM_IP=$2

/vagrant/siem/scripts/global-update-powershell-config.sh
/vagrant/siem/scripts/debian-upgrade.sh
/vagrant/siem/scripts/debian-install-java11.sh
/vagrant/siem/scripts/debian-check-siem-resources.sh
/vagrant/siem/scripts/debian-check-siem-certs.sh $SIEM_CN $SIEM_IP
/vagrant/siem/scripts/debian-install-siem.sh $SIEM_CN $SIEM_IP
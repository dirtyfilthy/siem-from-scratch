#!/bin/sh

. /vagrant/siem/conf/siem/config.sh

echo " "
echo "################################################"
echo "#                                               "
echo "# RESOURCE CHECK "                        
echo "#                                               "
echo "################################################"
echo " "

echo "[+] checking files..."
for FILE in $RESOURCE_PREREQUISITES; do
	if [ -f "/vagrant/siem/resources/${FILE}" ]; then
		printf "[?] checking %-40s... %s\n" ${FILE} OK
	else
		printf "[?] checking %-40s... %s\n" ${FILE} "NOT FOUND"
		echo "[!] /vagrant/siem/resources/${FILE} not found"
		echo "[+] running helpers/get-resources.sh (this will only run once)"
		/vagrant/siem/helpers/get-resources.sh ${ELKVERSION}
		break
	fi
done
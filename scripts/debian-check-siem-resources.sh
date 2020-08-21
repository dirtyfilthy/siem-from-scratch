. /vagrant/conf/siem/config.sh

echo "[+] checking files..."
for FILE in $RESOURCE_PREREQUISITES; do
	if [ -f "/vagrant/resources/${FILE}" ]; then
		printf "[?] checking %-40s... %s" ${FILE} OK
	else
		printf "[?] checking %-40s... %s" ${FILE} "NOT FOUND"
		echo "[!] /vagrant/resources/${FILE} not found"
		echo "[+] running helpers/get-resources.sh (this will only run once)"
		/vagrant/helpers/get-resources.sh ${ELKVERSION}
		break
	fi
done
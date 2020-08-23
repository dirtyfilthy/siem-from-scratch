#!/bin/sh
ROOTCERT=$1

if [ -z "$ROOTCERT"]; then
	echo "[!] ERROR: missing root cert argument"
	exit 1
fi

echo [+] copying $ROOTCERT to /usr/local/share/ca-certificates
cp $ROOTCERT /usr/local/share/ca-certificates/
echo [+] updating ca-certificates
update-ca-certificates
#!/bin/sh
ROOTCERT=$1
echo [+] copying $ROOTCERT to /usr/local/share/ca-certificates
cp $ROOTCERT /usr/local/share/ca-certificates/
echo [+] updating ca-certificates
update-ca-certificates
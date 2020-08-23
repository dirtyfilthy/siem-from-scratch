#!/bin/sh
CURRDIR="$(cd "$(dirname "$0")"; pwd)"
BASEDIR="$(cd $CURRDIR/..; pwd)"
CERTDIR=$BASEDIR/certs/myca
CONFDIR=$BASEDIR/conf/make-ca

echo [+] generating key
openssl genrsa -out $CERTDIR/myCA.key 2048 > /dev/null 2>&1

echo [+] generating root cert
openssl req -x509 -config $CONFDIR/myca.conf -new -nodes -key $CERTDIR/myCA.key -sha256 -days 1825 -out $CERTDIR/myCA.pem
cp $CERTDIR/myCA.pem $CERTDIR/myCA.crt

echo "[+] generating p12 (password is blank)"
openssl pkcs12 -export -out $CERTDIR/myCA.p12 -in $CERTDIR/myCA.pem -inkey $CERTDIR/myCA.key -passout pass:

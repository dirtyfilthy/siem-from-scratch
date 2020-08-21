#!/bin/sh
COMMONNAME=$1
IP=$2
OUTFILE=$3
CURRDIR="$(cd "$(dirname "$0")"; pwd)"
BASEDIR="$(cd $CURRDIR/..; pwd)"
CERTDIR=$BASEDIR/certs/myca
CONFDIR=$BASEDIR/conf/make-ca
KEY=${OUTFILE}.key
CRT=${OUTFILE}.crt
PFX=${OUTFILE}.p12

if [ "$#" -ne 3 ]; then
	echo "Usage: $0 COMMONNAME IP OUTFILEBASE"
	echo "create and sign a cert with ${CERTDIR}/myCA.pem root cert"
	echo "certs will be outputted to OUTFILEBASE.crt OUTFILEBASE.key OUTFILEBASE.p12"
	exit 1
fi

if [ -f $CERTDIR/myCA.srl ]; then
	SERIALOPT="-CAserial $CERTDIR/myCA.srl"
else
	SERIALOPT=-CAcreateserial
fi

TEMPCONF=$(mktemp)
TEMPCSR=$(mktemp)

echo [+] create conf $TEMPCONF
cat $CONFDIR/default.conf | sed "s/{{CN}}/$COMMONNAME/g;s/{{IP}}/$IP/g" > $TEMPCONF

echo [+] generate private key $KEY
openssl genrsa -out $KEY 2048 > /dev/null 2>&1

echo [+] generate cert request $TEMPCSR
openssl req -new -config $TEMPCONF -key $KEY -out $TEMPCSR

echo [+] creating cert $CRT
openssl x509 -extfile $TEMPCONF -extensions req_ext -req -in $TEMPCSR -CA $CERTDIR/myCA.pem -CAkey $CERTDIR/myCA.key $SERIALOPT \
-out $CRT -days 825 -sha256 

echo [+] creating .p12 $PFX
openssl pkcs12 -export -out $PFX -certfile $CERTDIR/myCA.pem -in $CRT -inkey $KEY -passout pass:

echo [+] cleaning up

rm $TEMPCONF
rm $TEMPCSR



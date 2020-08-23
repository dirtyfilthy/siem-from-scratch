#!/bin/sh
CURRDIR="$(cd "$(dirname "$0")"; pwd)"
BASEDIR="$(cd $CURRDIR/..; pwd)"

echo "[+] deleting $BASEDIR/resources/*"
rm -f $BASEDIR/resources/*

echo "[+] deleting $BASEDIR/certs/myca/*"
rm -f $BASEDIR/certs/myca/*

echo "[+] deleting $BASEDIR/certs/siem/*"
rm -f $BASEDIR/certs/siem/*

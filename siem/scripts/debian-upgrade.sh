#!/bin/sh

echo " "
echo "################################################"
echo "#                                               "
echo "# UPGRADE DEBIAN "                        
echo "#                                               "
echo "################################################"
echo " "

echo [+] updating repositories
apt-get -y update
echo [+] upgrading...
apt-get -y upgrade
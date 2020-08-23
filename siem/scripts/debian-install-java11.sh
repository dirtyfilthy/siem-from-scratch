#!/bin/sh
echo " "
echo "################################################"
echo "#                                               "
echo "# INSTALL JAVA 11"                        
echo "#                                               "
echo "################################################"
echo " "

echo [+] adding repository
add-apt-repository ppa:openjdk-r/ppa
echo [+] updating
apt-get update
echo [+] installing openjdk-11-jdk-headless
apt-get -y install openjdk-11-jdk-headless
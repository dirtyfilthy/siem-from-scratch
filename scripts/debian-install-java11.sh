echo [+] adding repository
add-apt-repository ppa:openjdk-r/ppa
echo [+] updating
apt-get update
echo [+] installing openjdk-11-jdk
apt-get -y install openjdk-11-jdk
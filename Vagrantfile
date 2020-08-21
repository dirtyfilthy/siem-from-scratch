# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

SIEM_IP   = "172.28.128.20"
SIEM_CN   = "siem.lab"

Vagrant.configure("2") do |config|
  config.vm.define "siem" do |cfg|
    cfg.vm.box = "ubuntu/xenial64"
    cfg.vm.hostname = "siem"
    cfg.vm.network :private_network, ip: SIEM_IP
    cfg.vm.provision "shell", path: "scripts/debian-upgrade.sh"
    cfg.vm.provision "shell", path: "scripts/debian-install-java11.sh"
    cfg.vm.provision "shell", path: "scripts/debian-check-siem-resources.sh"
    cfg.vm.provision "shell", path: "scripts/debian-check-siem-certs.sh", args: [SIEM_CN, SIEM_IP]
    cfg.vm.provision "shell", path: "scripts/debian-install-siem.sh", args: [SIEM_CN, SIEM_IP]
    cfg.vm.provider "virtualbox" do |vb, override|
      vb.customize ["modifyvm", :id, "--memory", 4096]
      vb.customize ["modifyvm", :id, "--cpus", 2]
      vb.customize ["modifyvm", :id, "--clipboard-mode", "bidirectional"]
      #vb.customize ["modifyvm", :id, "--uartmode1", "disconnected"]

    end
  end
end

# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

### COPY THESE VARIABLES

SIEM_IP   = "172.28.128.20"
SIEM_CN   = "siem.lab"
MONITORED_IP = "172.28.128.21"

Vagrant.configure("2") do |config|

  ### SIEM FROM SCRATCH

  config.vm.define "siem" do |cfg|
    cfg.vm.box = "ubuntu/xenial64"
    cfg.vm.hostname = "siem"
    cfg.vm.network :private_network, ip: SIEM_IP
    cfg.vm.provision "shell", path: "siem/scripts/debian-install-siem-one-line.sh", args: [SIEM_CN, SIEM_IP]
    cfg.vm.provider "virtualbox" do |vb, override|
      vb.customize ["modifyvm", :id, "--memory", 4096]
      vb.customize ["modifyvm", :id, "--cpus", 2]
      vb.customize ["modifyvm", :id, "--clipboard-mode", "bidirectional"]
    end
  end

  ### WINDOWS BOX MONITORED BY SIEM

  config.vm.define "monitored" do |cfg|
    cfg.vm.box = "gusztavvargadr/windows-server"

    cfg.vm.hostname = "monitored"
    cfg.vm.communicator = "winrm"
    cfg.winrm.transport = :plaintext
    cfg.winrm.basic_auth_only = true
    cfg.vm.network :private_network, ip: MONITORED_IP
    cfg.vm.provision "shell", path: "siem/installers/windows-install-winlogbeat.ps1", args: SIEM_IP
    cfg.vm.provision "shell", path: "siem/installers/windows-install-auditbeat.ps1",  args: SIEM_IP
    cfg.vm.provider "virtualbox" do |vb, override|
      vb.gui = true
      vb.customize ["modifyvm", :id, "--memory", 2048]
      vb.customize ["modifyvm", :id, "--cpus", 2]
      vb.customize ["modifyvm", :id, "--vram", "64"]
      vb.customize ['modifyvm', :id, '--graphicscontroller', 'vboxsvga']
      vb.customize ["modifyvm", :id, "--clipboard-mode", "bidirectional"]
      vb.customize ["setextradata", "global", "GUI/SuppressMessages", "all"]
      vb.customize ["storageattach", :id, 
                "--storagectl", "IDE Controller", 
                "--port", "0", "--device", "1", 
                "--type", "dvddrive", 
                "--medium", "emptydrive"]
    end
  end

end

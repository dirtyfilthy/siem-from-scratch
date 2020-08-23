If ($args.Count -ne 1){
    Write-Host '[!] ERROR: this provisioning script requires the SIEM IP as an argument to function!'
    Write-Host '[!] Edit your VagrantFile shell provisioning line to include either the "args" parameter'
    Write-Host '[!] with either the SIEM_IP variable or quoted "1.2.3.4" direct IP, like this:'
    Write-Host '[!]'
    Write-Host '[!] cfg.vm.provision "shell", path: "siem/installers/windows-install-filebeat.ps1", args: SIEM_IP'
    Write-Host '[!]'
    Write-Host '[!] or'
    Write-Host '[!]'
    Write-Host '[!] cfg.vm.provision \"shell\", path: "siem/installers/windows-install-filebeat.ps1", args: \"1.2.3.4\"'
    Write-Host '[!]'
    Write-Host '[!] exiting due to error'
    Exit 1
} 


$siem = $args[0]
. C:\vagrant\siem\conf\siem\config.ps1

Write-Host "[+] unzipping filebeat"
Expand-Archive "C:\vagrant\siem\resources\filebeat-$ELKVERSION-windows-x86_64.zip" "C:\Program Files"

Set-Location -Path "c:\Program Files\filebeat-$ELKVERSION-windows-x86_64"

Write-Host "[+] creating log directory"
mkdir logs

Write-Host "[+] creating config file"
(Get-Content c:\vagrant\siem\conf\filebeat\filebeat-win.yml).replace('localhost', $siem) | Set-Content filebeat.yml

Write-Host "[+] installing service"
.\install-service-filebeat.ps1

Write-Host "[+] starting service"
Start-Service -Name "filebeat"

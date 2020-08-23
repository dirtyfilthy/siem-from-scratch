If ($args.Count -ne 1){
    Write-Host '[!] ERROR: this provisioning script requires the SIEM IP as an argument to function!'
    Write-Host '[!] Edit your VagrantFile shell provisioning line to include either the "args" parameter'
    Write-Host '[!] with either the SIEM_IP variable or quoted "1.2.3.4" direct IP, like this:'
    Write-Host '[!]'
    Write-Host '[!] cfg.vm.provision "shell", path: "siem/installers/windows-install-winlogbeat.ps1", args: SIEM_IP'
    Write-Host '[!]'
    Write-Host '[!] or'
    Write-Host '[!]'
    Write-Host '[!] cfg.vm.provision \"shell\", path: "siem/installers/windows-install-winlogbeat.ps1", args: \"1.2.3.4\"'
    Write-Host '[!]'
    Write-Host '[!] exiting due to error'
    Exit 1
} 

# PARAMS

$siem = $args[0]

# CONFIG

. C:\vagrant\siem\conf\siem\config.ps1

# GLOBALS

$path = "c:\Program Files\winlogbeat-$ELKVERSION-windows-x86_64"

# maybe install sysmon?

Write-Host "[?] checking for sysmon service..."
If (Get-Service Sysmon -ErrorAction SilentlyContinue) {
    Write-Host "[!] service found, skipping install"
}
Else {
    Write-Host "[+] unzipping Sysmon.zip"
    Expand-Archive "C:\vagrant\siem\resources\Sysmon.zip" "C:\Windows\TEMP"
    Write-Host "[+] installing Sysmon.exe"
    C:\Windows\TEMP\Sysmon.exe -i -accepteula
}

Write-Host "[+] unzipping winlogbeat"
Expand-Archive "C:\vagrant\siem\resources\winlogbeat-$ELKVERSION-windows-x86_64.zip" "C:\Program Files"

Set-Location -Path $path

Write-Host "[+] creating log directory"
mkdir logs

Write-Host "[+] creating config file"
(Get-Content c:\vagrant\siem\conf\winlogbeat\winlogbeat.yml).replace('localhost', $siem) | Set-Content winlogbeat.yml

Write-Host "[+] installing service"
.\install-service-winlogbeat.ps1 # from zip

Write-Host "[+] starting service"
Start-Service -Name "winlogbeat"

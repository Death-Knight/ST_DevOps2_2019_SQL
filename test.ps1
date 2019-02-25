
Get-Command -Module SqlServer

Get-Module sqlserver -ListAvailable

$cr = Set-SqlCredential
Get-SqlInstance -Path "ADMIN" -Credential $cr 
get-help Get-SqlInstance  -Examples

Get-Service *SQL*

Get-WmiObject Win32_product | `
Where-Object {$_.Name -match "SQL" -AND $_.vendor -eq "Microsoft Corporation"} | `
Select-Object Name, Version

Get-NetFirewallRule | Select-Object -First 3
$r = Get-NetFirewallRule -name vm-monitoring-icmpv4
$r.GetCimSessionComputerName()

Get-NetFirewallProfile -PolicyStore ActiveStore


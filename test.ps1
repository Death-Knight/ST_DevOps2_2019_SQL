
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

# $myPassport = Get-Credential Administrator
# $vms = "192.168.130.1","192.168.130.2"
$myPassport = Get-Credential 'Server2\Администратор'
$vms = "192.168.100.242"
$myScript = {    
    $vmn = (Get-WmiObject Win32_OperatingSystem).CSName
    $Sers = "ALG" #stop
    #$Sers = "BFE" #run
    $se = Get-Service $Sers
    if ($se.Status -eq "Running") {    
        Write-Host -f "green" $vmn, $se.Name -Separator "-"
    }
    else {
        Write-Host -f "red"  $vmn, $se.Name -Separator "-"
    }
}
foreach ($vm in $vms) {
    Invoke-Command -ComputerName $vm -ScriptBlock $myScript -Credential $myPassport
}

$myPassport1 = Get-Credential VM1\Administrator
$myScript1 = {
    # "& E:\setup.exe"
    # start-process -filepath "& E:\setup.exe" -argumentlist ""
    # start-process -filepath "E:\setup.exe"
    #  start-process -filepath C:\TC\totalcmd.exe
    # ([wmiclass]"\\192.168.130.1\root\cimv2:Win32_Process").Create('C:\TC\totalcmd.exe')
    # cmd /c 'C:\TC\totalcmd.exe'
    # ([wmiclass]"Win32_Process").Create('C:\TC\totalcmd.exe')
    # if (Test-Path -Path "C:\TC\totalcmd.exe") {
    #     Write-Output "YES"
    #     $t = Get-WmiObject Win32_Process
    #     $t.Create("C:\TC\totalcmd.exe")
    # }
    # calc.exe
    PING.EXE "tut.by"
}
# Invoke-Command -ComputerName "192.168.130.1" -ScriptBlock $myScript1 -Credential $myPassport1
Invoke-Command -ComputerName "192.168.130.1" -ScriptBlock $myScript1 -Credential $myPassport


$s = New-PSSession -computername "192.168.130.1" -credential $myPassport1
Invoke-Command -session $s -scriptblock { & 'C:\TC\totalcmd.exe' }
Remove-PSSession $s

$t = Get-WmiObject Win32_Process
$t.Create("c:\Total Commander\totalcmd.exe")

winrs -r:"192.168.130.1" "C:\TC\totalcmd.exe"

$Computer = "vm1"
$Command = "C:\TC\totalcmd.exe" 
([wmiclass]"\\$Computer\root\cimv2:Win32_Process").create($Command)

wmic /node:"localhost" process call create "c:\Total Commander\totalcmd.exe" # !
wmic /node:"192.168.130.1" process call create "C:\TC\totalcmd.exe"

Test-WSMan "192.168.130.1"
Test-WSMan "192.168.100.242"

Invoke-Command -ComputerName "192.168.130.1" -ScriptBlock { 'C:\TC\totalcmd.exe' } -Credential $myPassport

get-item wsman:\localhost\Client\TrustedHosts

Invoke-Wmimethod -ComputerName "192.168.130.1" -Path win32_process -Name create -Argumentlist calc.exe
Invoke-Wmimethod -ComputerName "192.168.100.242" -Path win32_process -Name create -Argumentlist calc.exe

PING.EXE "tut.by"


# add firewall rules

$InstallNamedInstance = $true
$NameOfNamedInstance = "DEVOPS2019"        
if ($InstallNamedInstance) {
    $FWRule4 = "---1 SQL Named Instance $InstallNamedInstance"
    $SQLver = "12"
    $p_path = "%ProgramFiles%\Microsoft Sql Server\MSSQL$SQLver.$NameOfNamedInstance\MSSQL\Binn\sqlservr.exe"
    # $p_path
    New-NetFirewallRule -DisplayName "--FF" -Direction "Inbound" -Action "Allow" -Profile "Any" -Program $p_path
}

Get-NetFirewallRule -DisplayName "--- Inbound RDP TCP 3389" `
    | Select-Object PSComputerName, DisplayName, Enabled | Format-Table


Get-Service *SQL*

$newTempDBdir = "D:\new_tempdb"
if (!(Test-Path -Path $newTempDBdir)) {
    Write-Output "no folder"
    # New-Item -Path $newTempDBdir -ItemType Directory
}

$s = "'text"
$s

Get-Service -ServiceName Spooler
$s = Get-Service -ServiceName Spooler
$s.Status
$s.Stop()
Start-Sleep -Seconds 20
$s.Refresh()
$s.Status
$s.Start()
Start-Sleep -Seconds 20
$s.Refresh()
$s.Status


$s = "'$newTempDBdir\tempdb.ldf'"
$s

get-childitem -path "D:\111"

$MWFO_Log = "Microsoft-Windows-Forwarding/Operational"
Invoke-Command -ComputerName Server01 -ScriptBlock {Get-EventLog -LogName $Using:MWFO_Log -Newest 10}

$s = "1000"
"'$s"


# Чтобы получить путь скрипта:
$script_path = $MyInvocation.MyCommand.Path | split-path -parent
$script_path
# Чтобы получить имя файла скрипта:
$script_name = $MyInvocation.MyCommand.Name
$script_name

"PSScriptRoot is $PSScriptRoot"
"PSCommandPath is $PSCommandPath"
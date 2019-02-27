# автоматическая уставновка. local version
$SQLSetupSource = "E:\setup.exe"
$ConfFileSource = "C:\Install\def.ini" # default instance
& $SQLSetupSource /QS /ConfigurationFile=$ConfFileSource /IACCEPTSQLSERVERLICENSETERMS

$ConfFileSource1 = "C:\Install\def-named.ini" #named instance
& $SQLSetupSource /QS /ConfigurationFile=$ConfFileSource1 /IACCEPTSQLSERVERLICENSETERMS


# посмотрим имена машин и развернутых на них инстансах
[System.Data.Sql.SqlDataSourceEnumerator]::Instance.GetDataSources()

# или можно вот так
# [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo') | Out-Null 
# [Microsoft.SqlServer.Management.Smo.SmoApplication]::EnumAvailableSqlServers($true)  

# получим список уставновленных модулей MSSQL
# Write-Output "Installed MS SQL Components:"
# Get-WmiObject Win32_product | `
# Where-Object {$_.Name -match "SQL" -AND $_.vendor -eq "Microsoft Corporation"} | `
# Select-Object Name, Version

# -------------------------------------
# Settings
# -------------------------------------

$vms = "192.168.130.1", "192.168.130.2"
$vm1 = "192.168.130.1"
$vm2 = "192.168.130.2"

$myLogin = Get-Credential -UserName Administrator -Message "Admin login to VM."

$FWRule1 = "---1 Inbound RDP TCP 3389"
$FWRule2 = "---1 Inbound MSSQL TCP 1433"
$FWRule3 = "---1 Inbound MSSQL UDP 1434"

$InstallNamedInstance = $true
$NameOfNamedInstance = "DEVOPS2019"
$FWRule4 = "---1 SQL Named Instance $NameOfNamedInstance"
$SQLver = "12"
$p_path = "%ProgramFiles%\Microsoft SQL Server\MSSQL$SQLver.$NameOfNamedInstance\MSSQL\Binn\sqlservr.exe"

$mySQLLogin = "sa"
$newTempDBdir = "D:\new_tempdb"

$def_data_path = "C:\Program Files\Microsoft SQL Server\MSSQL$SQLver.MSSQLSERVER\MSSQL\DATA"
# tempdb.mdf and tempdb.ldf

# -------------------------------------

# add firewall rules + retun their states
# Import-Module NetSecurity

$FWRulesScriptStandart = {   
    $FWrules = @($Using:FWRule1, $Using:FWRule2, $Using:FWRule3)       

    New-NetFirewallRule -DisplayName $Using:FWRule1 -Direction "Inbound" `
        -Action "Allow" -Profile "Any" -Protocol "TCP" -LocalPort "3389" 
    New-NetFirewallRule -DisplayName $Using:FWRule2 -Direction "Inbound" `
        -Action "Allow" -Profile "Any" -Protocol "TCP" -LocalPort "1433" 
    New-NetFirewallRule -DisplayName $Using:FWRule3 -Direction "Inbound" `
        -Action "Allow" -Profile "Any" -Protocol "UDP" -LocalPort "1434"         
    
    if ($Using:InstallNamedInstance -eq $true) {
        # $FWrules = @($Using:FWRule1, $Using:FWRule2, $Using:FWRule3, $Using:FWRule4)
        $FWrules += $Using:FWRule4
        New-NetFirewallRule -DisplayName $Using:FWRule4 -Direction "Inbound" `
            -Action "Allow" -Profile "Any" -Program $Using:p_path
    }    
    foreach ($rule in $FWrules) {
        Get-NetFirewallRule -DisplayName $rule | `
            Select-Object PSComputerName, DisplayName, Enabled | Format-Table
    }
}
Invoke-Command -ComputerName $vm1 -ScriptBlock $FWRulesScriptStandart -Credential $myLogin


# посмотр установленных фич для серверов SQL

$results = @()
foreach ($vm in $vms) {
    Try {
        $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $vm)
        $RegKey = $Reg.OpenSubKey("SOFTWARE\\Microsoft\\Microsoft SQL Server\\Instance Names")
        $features = $RegKey.GetSubKeyNames();

        foreach ($i in $features) {
            ## Get installed Features 
            $key = "SOFTWARE\\Microsoft\\Microsoft SQL Server\\Instance Names\\$i"
            $FeatureKey = $Reg.OpenSubKey($key)

            $Value = $FeatureKey.GetValueNames();

            $instances = $FeatureKey.GetValueNames();
            foreach ($instance in $instances) {
                if ($instance -ne '') {
                    $instanceName = $FeatureKey.GetValue($instance)
                    $key = "SOFTWARE\\Microsoft\\Microsoft SQL Server\\$instanceName\\Setup"
                    $instanceKey = $Reg.OpenSubKey($key)

                    $object = New-Object PSObject
                    Add-Member -InputObject $object -MemberType NoteProperty -Name Computer -Value $vm
                    Add-Member -InputObject $object -MemberType NoteProperty -Name Feature -Value $i
                    Add-Member -InputObject $object -MemberType NoteProperty -Name Version -Value $instanceKey.GetValue('Version')
                    Add-Member -InputObject $object -MemberType NoteProperty -Name Edition -Value $instanceKey.GetValue('Edition')
                    $results += $object
                }
            }
        }
    }
    Catch {
        Write-Host "$vm - host is unreachable."
    }
}
# $results | Out-GridView
$results


# ----------------------------------------
# move tempdb
# ----------------------------------------

# create new folfer

$prepareFolder = {    
    if (!(Test-Path -Path $Using:newTempDBdir)) {
        Write-Output "no folder. creating..."
        $f = New-Item -Path $Using:newTempDBdir -ItemType Directory
        Write-Output "done"        
    }
    else {
        Write-Output "folder exist"
        Get-ChildItem -Path $Using:newTempDBdir
    }
}
Invoke-Command -ComputerName $vm1 -ScriptBlock $prepareFolder -Credential $myLogin

# execute moving sql-code
$mySQLLogin = "sa"
$mySQLPass = Get-Credential -UserName $mySQLLogin -Message "SQL 'sa' password."
# filename = N"'$Using:newTempDBdir\tempdb.mdf'")
# $ff1 = "N'$newTempDBdir\tempdb.mdf'"
$movingdb_SQLquery = {
    use master
    alter database tempdb
    modify file(
    name = tempdev,    
    filename = N'D:\new_tempdb\tempdb.mdf')
    go

    alter database tempdb
    modify file(
    name = templog,
    filename = N'D:\new_tempdb\templog.ldf')
    go
}
# $newTempDBdir
# $s_temp = "use master alter database tempdb modify file(name = tempdev, filename = N'D:\"+$newTempDBdir+"\tempdb.mdf') go"
# $s_temp = "use master\n alter database tempdb\n modify file(\nname = tempdev, \nfilename = N'D:\"+$newTempDBdir+"\tempdb.mdf') \ngo"
Invoke-Sqlcmd -ServerInstance $vm1 -Credential $mySQLPass -Query $movingdb_SQLquery


# restart  SQL service

$RestartSQLserviseScript = {
    $s = Get-Service -ServiceName "MSSQLSERVER"
    Write-Output ("Service "+$s.ServiceName+" status: "+$s.Status+". Waiting...")
    $s.Stop()
    Start-Sleep -Seconds 20
    $s.Refresh()
    Write-Output ("Service "+$s.ServiceName+" status: "+$s.Status+". Waiting...")    
    $s.Start()
    Start-Sleep -Seconds 20
    $s.Refresh()
    Write-Output ("Service "+$s.ServiceName+" status: "+$s.Status+". Done.")    
    # check new files in new directory
    Get-ChildItem -Path $Using:newTempDBdir
}
Invoke-Command -ComputerName $vm1 -ScriptBlock $RestartSQLserviseScript -Credential $myLogin


# remove old tempdb.mdf and templog.ldf

$RemoveOldFiles = {
    try {
        Remove-Item -Path "$Using:def_data_path\tempdb.mdf"
        Remove-Item -Path "$Using:def_data_path\templog.ldf"
        Get-ChildItem -Path $Using:def_data_path
        Write-Output ("tempdb.mdf, templog.ldf - its gone.")
    }
    catch {
        Write-Output ("Warning! can't delete 'tempdb.mdf' or 'templog.ldf'")        
    }    
}
Invoke-Command -ComputerName $vm1 -ScriptBlock $RemoveOldFiles -Credential $myLogin

# -------------------------------------------

$da
$qw = "CREATE DATABASE Sales ON (NAME = Sales_dat,    FILENAME = 'D:\Data\Sales.mdf',
 SIZE = 100MB, MAXSIZE = 500MB, FILEGROWTH = 20%) LOG ON   (NAME = Sales_log,
    FILENAME = 'D:\Logs\Sales.ldf', SIZE = 20MB, MAXSIZE = UNLIMITED, FILEGROWTH = 10MB); "
Invoke-Sqlcmd -ServerInstance $vm1 -Credential $mySQLPass -Query $qw

$qw_drop = "DROP DATABASE Sales"
Invoke-Sqlcmd -ServerInstance $vm1 -Credential $mySQLPass -Query $qw_drop



$nw = "
    use master
    alter database tempdb
    modify file(
    name = tempdev,    
    filename = N'$newTempDBdir\tempdb.mdf')
    go

    alter database tempdb
    modify file(
    name = templog,
    filename = N'$newTempDBdir\templog.ldf')
    go
"
Invoke-Sqlcmd -ServerInstance $vm1 -Credential $mySQLPass -Query $nw

$movingdb_SQLquery = {
    
}

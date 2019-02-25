# автоматическая уставновка 
$SQLSetupSource = "E:\setup.exe"
$ConfFileSource = "C:\Install\def.ini" # default instance
& $SQLSetupSource /QS /ConfigurationFile=$ConfFileSource /IACCEPTSQLSERVERLICENSETERMS

$ConfFileSource1 = "C:\Install\def-named.ini" #named instance
& $SQLSetupSource /QS /ConfigurationFile=$ConfFileSource1 /IACCEPTSQLSERVERLICENSETERMS



# создаем правила вфаерволе для возможности подключения
# Import-Module NetSecurity
New-NetFirewallRule -DisplayName "--- Inbound MSSQL TCP 1433" -Direction "Inbound" `
    -Action "Allow" -Profile "Any" -Protocol "TCP" -LocalPort "1433" 

New-NetFirewallRule -DisplayName "--- Inbound MSSQL UDP 1434" -Direction "Inbound" `
    -Action "Allow" -Profile "Any" -Protocol "UDP" -LocalPort "1434" 

New-NetFirewallRule -DisplayName "--- Inbound RDP TCP 3389" -Direction "Inbound" `
    -Action "Allow" -Profile "Any" -Protocol "TCP" -LocalPort "3389" 

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

# посмотр установленных фич для серверов SQL
$computers = "192.168.130.1","192.168.130.1","192.168.130.1","admin"
$results = @()
foreach ($computer in $computers) {
    Try {
        $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer)
        $RegKey= $Reg.OpenSubKey("SOFTWARE\\Microsoft\\Microsoft SQL Server\\Instance Names")
        $features = $RegKey.GetSubKeyNames();

        foreach ($i in $features) 
        {
            ## Get installed Features 
            $key = "SOFTWARE\\Microsoft\\Microsoft SQL Server\\Instance Names\\$i"
            $FeatureKey= $Reg.OpenSubKey($key)

            $Value = $FeatureKey.GetValueNames();

            $instances = $FeatureKey.GetValueNames();
            foreach ($instance in $instances) {
                if ($instance -ne '') {
                    $instanceName = $FeatureKey.GetValue($instance)
                    $key = "SOFTWARE\\Microsoft\\Microsoft SQL Server\\$instanceName\\Setup"
                    $instanceKey= $Reg.OpenSubKey($key)

                    $object = New-Object PSObject
                    Add-Member -InputObject $object -MemberType NoteProperty -Name Computer -Value $computer
                    Add-Member -InputObject $object -MemberType NoteProperty -Name Feature -Value $i
                    Add-Member -InputObject $object -MemberType NoteProperty -Name Version -Value $instanceKey.GetValue('Version')
                    Add-Member -InputObject $object -MemberType NoteProperty -Name Edition -Value $instanceKey.GetValue('Edition')
                    $results += $object
                }
            }
        }
    }
    Catch {
        Write-Host "$computer Not Reachable"
    }
}
# $results | Out-GridView
$results
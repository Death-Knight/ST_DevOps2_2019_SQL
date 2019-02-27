# Подключиться к обоим серверам MSSQL

# локальное подключение (идентификация win)
Import-Module SqlServer
$myLogin = "sa"
$myPass = Get-Credential -UserName $myLogin -Message "Enter SQL Password"
Invoke-Sqlcmd -ServerInstance $env:COMPUTERNAME -Credential $myPass -Query 'select @@SERVERNAME;'


# подключение к удаленному серверу
$myTempPass = Read-Host "Enter password for User 'sa'!" -AsSecureString
$myPass1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($myTempPass))
Invoke-Sqlcmd -ServerInstance "192.168.130.1"  -Username "sa" -Password $myPass1 -Query 'select @@servername;'
Invoke-Sqlcmd -ServerInstance "192.168.130.2"  -Username "sa" -Password $myPass1 -Query 'select @@servername;'

$myTempPass = Read-Host "Enter password for User 'sa' on the VM3!" -AsSecureString
$myPass1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($myTempPass))
Invoke-Sqlcmd -ServerInstance 192.168.130.3  -Username "sa" -Password $myPass1 -Query 'select @@servername;'
# Invoke-Sqlcmd -ServerInstance 192.168.130.10  -Username "sa" -Password $myPass1 -Query 'select @@servername;'



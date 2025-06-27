$PrimaryServer = 'Server_1'
$SecondaryServer = 'Server_2'
$DRServer = 'Server_3'


#Stop SQL Services
Invoke-Command -ComputerName $PrimaryServer -ScriptBlock { Stop-Service -Name 'MSSQLSERVER' -Force }
Invoke-Command -ComputerName $SecondaryServer -ScriptBlock { Stop-Service -Name 'MSSQLSERVER' -Force }
Invoke-Command -ComputerName $DRServer -ScriptBlock { Stop-Service -Name 'MSSQLSERVER' -Force }

#Stop Agent Services
Invoke-Command -ComputerName $PrimaryServer -ScriptBlock { Stop-Service -Name 'SQLSERVERAGENT' }
Invoke-Command -ComputerName $SecondaryServer -ScriptBlock { Stop-Service -Name 'SQLSERVERAGENT' }
Invoke-Command -ComputerName $DRServer -ScriptBlock { Stop-Service -Name 'SQLSERVERAGENT' }


#Check Server

#MSSQLSERVER
Invoke-Command -ComputerName $PrimaryServer -ScriptBlock { Get-Service -Name MSSQLSERVER}
Invoke-Command -ComputerName $SecondaryServer -ScriptBlock { Get-Service -Name MSSQLSERVER}
Invoke-Command -ComputerName $DRServer -ScriptBlock { Get-Service -Name MSSQLSERVER}
#SQLSERVERAGENT
Invoke-Command -ComputerName $PrimaryServer -ScriptBlock { Get-Service -Name SQLSERVERAGENT}
Invoke-Command -ComputerName $SecondaryServer -ScriptBlock { Get-Service -Name SQLSERVERAGENT}
Invoke-Command -ComputerName $DRServer -ScriptBlock { Get-Service -Name SQLSERVERAGENT}


#Restart Server

Restart-Computer -ComputerName $PrimaryServer -Force
Restart-Computer -ComputerName $SecondaryServer -Force
Restart-Computer -ComputerName $DRServer -Force

#Shutdown Server

Stop-Computer -ComputerName $PrimaryServer -Force
Stop-Computer -ComputerName $SecondaryServer -Force
Stop-Computer -ComputerName $DRServer -Force
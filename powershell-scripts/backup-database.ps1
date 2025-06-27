#	Takes a full backup of a database


# Backup SQL Server database using sqlcmd
$server = "localhost"
$database = "YourDatabaseName"
$backupPath = "C:\Backup\$database-$(Get-Date -Format 'yyyyMMddHHmmss').bak"

Invoke-Expression "sqlcmd -S $server -Q `"BACKUP DATABASE [$database] TO DISK = N'$backupPath' WITH INIT`""
Write-Host "Backup complete: $backupPath"

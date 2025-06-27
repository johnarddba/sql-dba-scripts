# 	Retrieves available disk space on SQL Server


# Check disk space usage for C: drive
Get-PSDrive C | Select-Object Name, @{Name="Used(GB)";Expression={[math]::round(($_.Used/1GB),2)}}, @{Name="Free(GB)";Expression={[math]::round(($_.Free/1GB),2)}}

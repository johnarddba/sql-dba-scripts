# Verifies SQL Server services are running


# Check if SQL Server service is running
$serviceName = "MSSQLSERVER"
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($service.Status -eq 'Running') {
    Write-Host "$serviceName is running."
} else {
    Write-Host "$serviceName is NOT running!"
}

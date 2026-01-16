# Run this in PowerShell to check a file's age
$FilePath = "\\tshd53fsxot0001.hedgeservtest.com\rnd_db_tlogs\DR_Sync\TRND53MSSQL5161\hsolyrnd5162\wk_3_Tuesday_202601130516_hsolyrnd5162_DR_Prod_FULL_part0.LBK"
if (Test-Path $FilePath) {
    $file = Get-Item $FilePath
    $age = [math]::Round(((Get-Date) - $file.LastWriteTime).TotalMinutes)
    Write-Output "File age: $age minutes ($(($age / 60).ToString('F1')) hours)"
} else {
    Write-Output "File not found"
}
$ServerName = 'servername' # Replace with your server name
$Jobname = 'daily_Backup_FULL_ALL_Databases'

while ($true) {

    $job = Invoke-Sqlcmd -ServerInstance $ServerName -Database msdb -Query "
        SELECT 
	    ja.start_execution_date

        FROM msdb.dbo.sysjobs j
        JOIN msdb.dbo.sysjobactivity ja 
        ON j.job_id = ja.job_id
        WHERE j.name = '$JobName'
        AND ja.stop_execution_date IS NULL
    
    "
    if ($job) {
        $start = [datetime]$job.start_execution_date
        $elapsed = (Get-Date) - $start
        $percent = [Math]::Min(($elapsed.TotalMinutes / 30) * 100, 100)

        Write-Progress -Activity "Running $JobName" `
                       -Status "$([int]$percent)% Complete" `
                       -PercentComplete $percent 
        
    }
    else {
        Write-Host "$JobName not running" -ForegroundColor Green
    
    }

    Start-Sleep 5

}


Cannot find an overload for "op_Subtraction" and the argument count: "2".
At line:19 char:9
+         $elapsed = (Get-Date) - $start
+         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [], MethodException
    + FullyQualifiedErrorId : MethodCountCouldNotFindBest
 
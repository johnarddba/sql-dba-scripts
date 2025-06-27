#	Gets status of failed SQL Agent jobs


# List SQL Agent Jobs with failed last run
$server = "localhost"
$Query = @"
SELECT name, last_run_date, last_run_time, last_run_outcome
FROM msdb.dbo.sysjobs_view AS j
JOIN msdb.dbo.sysjobservers AS s ON j.job_id = s.job_id
WHERE s.last_run_outcome = 0
"@

Invoke-Sqlcmd -ServerInstance $server -Database msdb -Query $Query

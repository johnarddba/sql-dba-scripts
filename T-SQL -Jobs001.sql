SELECT TOP 1
j.name AS Job_name,
CONVERT(nvarchar,ja.start_execution_date,0) AS start_job, 
CONVERT(nvarchar,ja.stop_execution_date,0) AS end_job,
RIGHT('00' + CAST(total_duration / 10000 AS VARCHAR(2)), 2) + ':' + RIGHT('00' + CAST((total_duration % 10000) / 100 AS VARCHAR(2)), 2) + ':' + RIGHT('00' + CAST(total_duration % 100 AS VARCHAR(2)), 2) AS duration
FROM 
msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobactivity ja
ON j.job_id = ja.job_id
JOIN (SELECT instance_id, SUM(run_duration) as total_duration FROM msdb.dbo.sysjobhistory GROUP BY instance_id) jh
ON ja.job_history_id = jh.instance_id
WHERE j.name LIKE 'wknd_MAINT%'
ORDER BY ja.start_execution_date DESC
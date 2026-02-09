SET NOCOUNT ON;

SELECT sj.name AS Name,
    --sh.step_name AS StepName,
    CONVERT(nvarchar,shp.LastRunStartDateTime,0) AS StartDate,
    CONVERT(nvarchar,DATEADD(SECOND, shp.LastRunDurationSeconds, shp.LastRunStartDateTime),0) AS LastRunFinishDateTime,
    --shp.LastRunDurationSeconds,
    CASE
        WHEN sh.run_duration > 235959
            THEN CAST((CAST(LEFT(CAST(sh.run_duration AS VARCHAR),
                LEN(CAST(sh.run_duration AS VARCHAR)) - 4) AS INT) / 24) AS VARCHAR)
                    + '.' + RIGHT('00' + CAST(CAST(LEFT(CAST(sh.run_duration AS VARCHAR),
                LEN(CAST(sh.run_duration AS VARCHAR)) - 4) AS INT) % 24 AS VARCHAR), 2)
                    + ':' + STUFF(CAST(RIGHT(CAST(sh.run_duration AS VARCHAR), 4) AS VARCHAR(6)), 3, 0, ':')
        ELSE STUFF(STUFF(RIGHT(REPLICATE('0', 6) + CAST(sh.run_duration AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
        END AS [LastRunDuration (d.HH:MM:SS)]
FROM msdb.dbo.sysjobs sj
INNER JOIN sys.databases d ON sj.name = 'WKND_MAINT_' + d.name
INNER JOIN msdb.dbo.sysjobhistory sh ON sj.job_id = sh.job_id
CROSS APPLY (SELECT DATETIMEFROMPARTS(sh.run_date / 10000, -- years
        sh.run_date % 10000 / 100, -- months
        sh.run_date % 100, -- days
        sh.run_time / 10000, -- hours
        sh.run_time % 10000 / 100, -- minutes
        sh.run_time % 100, -- seconds
        0 -- milliseconds
    ) AS LastRunStartDateTime,
    (sh.run_duration / 10000) * 3600 -- convert hours to seconds, can be greater than 24
    + ((sh.run_duration % 10000) / 100) * 60 -- convert minutes to seconds
    + (sh.run_duration % 100) AS LastRunDurationSeconds
) AS shp
WHERE d.name NOT IN ('master', 'model', 'msdb', 'tempdb')
AND d.state_desc = 'ONLINE';
GO
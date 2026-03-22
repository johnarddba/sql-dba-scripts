SELECT 
    database_name,
    CAST(first_lsn AS VARCHAR(25)) AS first_lsn,
    CAST(last_lsn AS VARCHAR(25)) AS last_lsn,
    CAST(checkpoint_lsn AS VARCHAR(25)) AS checkpoint_lsn,
    CAST(database_backup_lsn AS VARCHAR(25)) AS database_backup_lsn,
    backup_start_date,
    backup_finish_date,
    CASE [type] 
        WHEN 'D' THEN 'Full' 
        WHEN 'I' THEN 'Differential' 
        WHEN 'L' THEN 'Transaction Log' 
    END AS BackupType
FROM 
    msdb.dbo.backupset
WHERE 
    database_name = 'YourDatabaseName'
ORDER BY 
    backup_start_date DESC;

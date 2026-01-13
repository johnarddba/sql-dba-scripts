USE master;
GO

DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql += N'RESTORE DATABASE ' + QUOTENAME(name) + N' WITH RECOVERY;' + CHAR(13) + CHAR(10)
    + N'ALTER DATABASE ' + QUOTENAME(name) + N' SET OFFLINE WITH ROLLBACK IMMEDIATE;' + CHAR(13) + CHAR(10)
FROM sys.databases
--WHERE database_id > 5  -- Exclude system databases
WHERE name NOT IN ('master','tempdb','model','msdb','hsadmin')

  AND (is_read_only = 1 OR state_desc = 'STANDBY')  -- Target read-only or standby
  AND state = 0;  -- Ensure the database is ONLINE (standby databases are ONLINE but read-only)

IF @sql <> N''
BEGIN
    PRINT 'Executing the following commands:' + CHAR(13) + CHAR(10) + @sql;
    --EXEC sp_executesql @sql;
	PRINT @SQL

	


END


ELSE
BEGIN
    PRINT 'No user databases found in Standby/Read-Only mode.';
END
GO
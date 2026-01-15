-- Restore all user databases to STANDBY mode and run a stored procedure after each restore
-- This script:
-- 1) Finds all ONLINE user databases
-- 2) For each database, restores it to STANDBY (read-only, reversible) 
-- 3) After each restore, executes a stored procedure (e.g., sp_resync_users)

USE master;
GO

-- Configuration: Modify these values for your environment
DECLARE @BackupFolder NVARCHAR(512) = N'\\backup_server\backups\'; -- Path where full backup files are located
DECLARE @StoredProcToRun NVARCHAR(128) = N'sp_resync_users'; -- Stored procedure to run after each restore
DECLARE @DryRun BIT = 0; -- Set to 1 to print commands without executing them

-- Working variables
DECLARE @DB SYSNAME;
DECLARE @BackupFile NVARCHAR(2000);
DECLARE @RestoreSQL NVARCHAR(MAX);
DECLARE @ExecSQL NVARCHAR(MAX);

-- Create temp table to hold list of user databases
IF OBJECT_ID('tempdb..#DBsToRestore') IS NOT NULL DROP TABLE #DBsToRestore;
CREATE TABLE #DBsToRestore (
    DBName SYSNAME,
    ProcessedFlag BIT DEFAULT 0
);

-- Populate temp table with all ONLINE user databases (exclude system databases)
INSERT INTO #DBsToRestore (DBName)
SELECT name
FROM sys.databases
WHERE database_id > 4  -- Skip master, tempdb, model, msdb
  AND state_desc = 'ONLINE'
  AND is_read_only = 0  -- Only include read-write databases
ORDER BY name;

PRINT 'Found ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' databases to restore.';
PRINT '';

-- Loop through each database and restore to STANDBY
WHILE EXISTS (SELECT 1 FROM #DBsToRestore WHERE ProcessedFlag = 0)
BEGIN
    -- Get next database
    SELECT TOP 1 @DB = DBName FROM #DBsToRestore WHERE ProcessedFlag = 0 ORDER BY DBName;

    PRINT '========================================';
    PRINT 'Processing database: ' + @DB;
    PRINT '========================================';

    -- Build the backup file path (assumes standard naming: DB_Full.bak)
    SET @BackupFile = @BackupFolder + @DB + '_Full.bak';

    -- Build the RESTORE command to STANDBY mode
    SET @RestoreSQL = N'RESTORE DATABASE [' + @DB + N'] FROM DISK = N''' + @BackupFile + N''' WITH STANDBY = N''' 
                    + N'C:\SQL_Rollback\' + @DB + N'.undo'', REPLACE, STATS = 10';

    PRINT 'Restore command:';
    PRINT @RestoreSQL;
    PRINT '';

    -- Execute the restore (or print if dry-run)
    IF @DryRun = 1
    BEGIN
        PRINT '[DRY RUN] Would execute restore command above';
    END
    ELSE
    BEGIN
        BEGIN TRY
            PRINT 'Executing restore...';
            EXEC sp_executesql @RestoreSQL;
            PRINT 'Restore completed successfully for ' + @DB;
        END TRY
        BEGIN CATCH
            PRINT 'ERROR restoring ' + @DB + ': ' + ERROR_MESSAGE();
            UPDATE #DBsToRestore SET ProcessedFlag = 1 WHERE DBName = @DB;
            CONTINUE;
        END CATCH
    END

    -- After successful restore, run the stored procedure
    PRINT '';
    PRINT 'Running post-restore stored procedure: ' + @StoredProcToRun;

    -- Build command to run stored proc (in the context of the restored database)
    SET @ExecSQL = N'USE [' + @DB + N']; IF OBJECT_ID(''' + @StoredProcToRun + ''', ''P'') IS NOT NULL EXEC ' + @StoredProcToRun + N'; ELSE PRINT ''' + @StoredProcToRun + N' not found in ' + @DB + N'''';

    IF @DryRun = 1
    BEGIN
        PRINT '[DRY RUN] Would execute:';
        PRINT @ExecSQL;
    END
    ELSE
    BEGIN
        BEGIN TRY
            EXEC sp_executesql @ExecSQL;
            PRINT 'Post-restore procedure completed for ' + @DB;
        END TRY
        BEGIN CATCH
            PRINT 'WARNING: Post-restore procedure failed for ' + @DB + ': ' + ERROR_MESSAGE();
            -- Continue with next database even if proc fails
        END CATCH
    END

    PRINT '';

    -- Mark this database as processed
    UPDATE #DBsToRestore SET ProcessedFlag = 1 WHERE DBName = @DB;
END

-- Cleanup
DROP TABLE #DBsToRestore;

PRINT '========================================';
PRINT 'Restore operation completed.';
PRINT '========================================';
GO

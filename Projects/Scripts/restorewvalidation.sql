USE master;
GO

DECLARE
	@BasePath nvarchar(512) = '\\tshd53fsxot0001.hedgeservtest.com\rnd_db_tlogs\DR_Sync\',
	--@BasePath nvarchar(512) = N'\\hedgeservcustomers.com\shared\s3-db-backups\prd\DR_Sync\'
	@ServerTag nvarchar(128) = REPLACE(LEFT(@@SERVERNAME, CHARINDEX('\', @@SERVERNAME + '\') -1),'TRND52','TRND53'),
	@MaxBackupAgeHours INT = 5, -- Maximum acceptable backup age in hours; skip if older
	@SecondaryServer NVARCHAR(256) = N'TRND02', -- Secondary server name for parallel job enablement
	@DB sysname,
	@Location nvarchar(2000),
	@SQL nvarchar(max),
	@BackupAgeMinutes INT,
	@CurrentTime DATETIME2 = GETDATE()

IF OBJECT_ID('tempdb..#UserDBs') IS NOT NULL DROP TABLE #UserDBs;
CREATE TABLE #UserDBs (DBName sysname);

INSERT INTO #UserDBs (DBName)
SELECT name FROM sys.databases
WHERE name NOT IN ('master','model','msdb','tempdb','hsadmin')
AND state_desc = 'ONLINE';

WHILE EXISTS (SELECT 1 FROM #UserDBs)
BEGIN
	SELECT TOP 1 @DB = DBName FROM #UserDBs ORDER BY DBName;

	SET @Location = NULL;
	IF EXISTS (SELECT 1 FROM sys.configurations WHERE name = 'xp_cmdshell' AND value =1)
	BEGIN
		CREATE TABLE #dir (line nvarchar(4000));
		DECLARE @DirCmd nvarchar(4000) = 'dir "' + @BasePath + @ServerTag + '\' + @DB + '\*_DR_Prod_FULL_part0.LBK" /b /o:-d';
		INSERT INTO #dir EXEC xp_cmdshell @DirCmd;
		SELECT TOP 1 @Location = @BasePath + @ServerTag + '\' + @DB + '\' + line FROM #dir WHERE line IS NOT NULL and line <> '';
		DROP TABLE #dir;
	END
	ELSE
	BEGIN
		PRINT 'xp_cmdshell is disabled'
	END
	IF @Location IS NULL
	BEGIN
		SET @Location = @BasePath + @ServerTag + '\' + @DB + '\' + @ServerTag + '_' + @DB + '_' + 'DR_Prod_FULL_part0.LBK';
	END

	-- Check backup file age using PowerShell if xp_cmdshell is enabled
	SET @BackupAgeMinutes = -1; -- Default to -1 (unknown); will skip if still -1

	IF EXISTS (SELECT 1 FROM sys.configurations WHERE name = 'xp_cmdshell' AND value = 1)
	BEGIN
		CREATE TABLE #fileinfo (info varchar(8000));
		DECLARE @GetFileAge VARCHAR(8000) = 'powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Test-Path ''' + @Location + ''') { $f = Get-Item ''' + @Location + '''; $age = [math]::Round(((Get-Date) - $f.LastWriteTime).TotalMinutes); Write-Output $age } else { Write-Output ''FILE_NOT_FOUND'' }"';
		INSERT INTO #fileinfo EXEC xp_cmdshell @GetFileAge;
		SELECT TOP 1 @BackupAgeMinutes = TRY_CONVERT(INT, info) FROM #fileinfo WHERE info NOT LIKE '%FILE_NOT_FOUND%' AND ISNUMERIC(info) = 1;
		DROP TABLE #fileinfo;
	END

	-- Validate backup age before proceeding
	IF @BackupAgeMinutes IS NOT NULL AND @BackupAgeMinutes >= 0
	BEGIN
		IF @BackupAgeMinutes > (@MaxBackupAgeHours * 60)
		BEGIN
			PRINT 'WARNING: Backup for ' + @DB + ' is ' + CAST(@BackupAgeMinutes / 60 AS NVARCHAR(10)) + ' hours old (max allowed: ' + CAST(@MaxBackupAgeHours AS NVARCHAR(10)) + '). Skipping restore.';
			DELETE FROM #UserDBs WHERE DBName = @DB;
			CONTINUE;
		END
		ELSE
		BEGIN
			PRINT 'Backup for ' + @DB + ' is ' + CAST(@BackupAgeMinutes / 60.0 AS NVARCHAR(10)) + ' hours old. Proceeding with restore.';
		END
	END
	ELSE
	BEGIN
		PRINT 'WARNING: Could not determine backup age for ' + @DB + '. Proceeding with caution.';
	END

	--Checking the store procedure
	--PRINT 'use master; EXEC sp_Reload2_AG_DB @DBNAME=''' + @DB + ''', @BackupName=''' + @Location + '''';
	--Actual execution
	BEGIN TRY
		SET @SQL = N'use master; EXEC sp_Reload2_AG_DB @DBNAME=@db, @BackupName=@loc';
		EXEC sp_executesql
			@SQL,
			N'@db sysname, @loc nvarchar(2000)',
			@db = @DB,
			@loc = @Location;
		PRINT 'Restore completed for ' + @DB;
	END TRY
	BEGIN CATCH
		PRINT 'Error in ' + @DB + ': ' + ERROR_MESSAGE();
	END CATCH

	DELETE FROM #UserDBs WHERE DBName = @DB;
END

--Cleanup temp table
IF OBJECT_ID('tempdb..#UserDBs') IS NOT NULL DROP TABLE #UserDBs;

-- ========================================
-- All restores completed - Now enable jobs
-- ========================================
PRINT '';
PRINT '========================================';
PRINT 'All restores completed. Enabling jobs...';
PRINT '========================================';

-- Enable jobs on PRIMARY and SECONDARY in parallel
DECLARE @JobPattern1 NVARCHAR(128) = N'wknd_MAINT%';
DECLARE @JobPattern2 NVARCHAR(128) = N'daily_TRAN_LOG%';

-- Create a temp table to hold jobs to enable
IF OBJECT_ID('tempdb..#JobsToEnable') IS NOT NULL DROP TABLE #JobsToEnable;
CREATE TABLE #JobsToEnable (job_name SYSNAME);

-- Find jobs matching both patterns
INSERT INTO #JobsToEnable (job_name)
SELECT name FROM msdb.dbo.sysjobs
WHERE (name LIKE @JobPattern1 OR name LIKE @JobPattern2)
  AND enabled = 0;

-- Enable jobs on PRIMARY and SECONDARY in parallel using PowerShell
IF EXISTS (SELECT 1 FROM #JobsToEnable)
BEGIN
	-- Build enable command for PRIMARY (local instance)
	DECLARE @EnableJobsSQL NVARCHAR(MAX) = N'';
	SELECT @EnableJobsSQL += N'EXEC msdb.dbo.sp_update_job @job_name = N''' + job_name + N''', @enabled = 1; '
	FROM #JobsToEnable;

	-- Execute on PRIMARY
	EXEC sp_executesql @EnableJobsSQL;

	-- Build PowerShell command to enable jobs on SECONDARY in parallel
	DECLARE @SecondaryJobEnableCmd NVARCHAR(MAX) = N'powershell -NoProfile -ExecutionPolicy Bypass -Command "' +
		N'$SecondaryServer = ''' + @SecondaryServer + N'''; ' +
		N'$ConnectionString = ''Server=' + @SecondaryServer + N';Integrated Security=true;''; ' +
		N'$SqlConnection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString); ' +
		N'$SqlConnection.Open(); ' +
		STUFF((SELECT N' $SqlCmd = New-Object System.Data.SqlClient.SqlCommand(''EXEC msdb.dbo.sp_update_job @job_name = ''''''' + job_name + N''''''', @enabled = 1'', $SqlConnection); ' +
			   N' $SqlCmd.ExecuteNonQuery() | Out-Null; ' +
			   N' Write-Host ''Enabled job (' + @SecondaryServer + N'): ' + job_name + N'''; '
			   FROM #JobsToEnable 
			   FOR XML PATH('')), 1, 1, '') +
		N' $SqlConnection.Close()' +
		N'"';

	-- Execute on SECONDARY (parallel)
	DECLARE @SecondaryJobEnableCmd_VC VARCHAR(8000) = CONVERT(VARCHAR(8000), @SecondaryJobEnableCmd);
	
	IF @DryRun = 1
	BEGIN
		PRINT '[DRY RUN] Would execute jobs on SECONDARY (' + @SecondaryServer + '):';
		PRINT @SecondaryJobEnableCmd;
	END
	ELSE
	BEGIN
		EXEC xp_cmdshell @SecondaryJobEnableCmd_VC;
	END

	-- Print enabled jobs on PRIMARY
	PRINT 'Jobs enabled on PRIMARY (local instance):';
	SELECT 'Enabled: ' + job_name AS JobStatus FROM #JobsToEnable;
END
ELSE
BEGIN
	PRINT 'No matching disabled jobs found.';
END

DROP TABLE #JobsToEnable;

PRINT '';
PRINT '========================================';
PRINT 'Job enablement completed (Primary + Secondary).';
PRINT '========================================';



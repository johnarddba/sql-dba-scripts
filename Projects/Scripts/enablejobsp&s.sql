
-- Get secondary server by incrementing the LAST numeric sequence (e.g., TRND52MSSQL5161 -> TRND52MSSQL5162)
DECLARE @CurrentServer NVARCHAR(255) = LEFT(@@SERVERNAME, CHARINDEX('\', @@SERVERNAME + '\') - 1),
        @LastNumberStart INT,
        @LastNumberEnd INT,
        @CurrentNumber INT,
        @SecondaryNumber INT,
        @Prefix NVARCHAR(255),
        @SecondaryServer NVARCHAR(255);

-- Find the position of the last numeric sequence
SET @LastNumberEnd = LEN(@CurrentServer);
WHILE @LastNumberEnd > 0 AND SUBSTRING(@CurrentServer, @LastNumberEnd, 1) NOT LIKE '[0-9]'
    SET @LastNumberEnd = @LastNumberEnd - 1;

-- Find the start of the last numeric sequence
SET @LastNumberStart = @LastNumberEnd;
WHILE @LastNumberStart > 0 AND SUBSTRING(@CurrentServer, @LastNumberStart - 1, 1) LIKE '[0-9]'
    SET @LastNumberStart = @LastNumberStart - 1;

-- Extract and increment
SET @CurrentNumber = CAST(SUBSTRING(@CurrentServer, @LastNumberStart, @LastNumberEnd - @LastNumberStart + 1) AS INT);
SET @SecondaryNumber = @CurrentNumber + 1;
SET @Prefix = LEFT(@CurrentServer, @LastNumberStart - 1);

-- Build secondary server name
SET @SecondaryServer = @Prefix + CAST(@SecondaryNumber AS NVARCHAR(10));

PRINT 'PRIMARY: ' + @CurrentServer;
PRINT 'SECONDARY: ' + @SecondaryServer;
PRINT '';

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




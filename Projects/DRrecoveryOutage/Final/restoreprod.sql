USE master;
GO

--Configurations and Variables
DECLARE
	--rnd: \\rndshared\
	--prd: \\prdshared\
	@BasePath nvarchar(512) = '\\shared\',
	
	@ServerTag nvarchar(128) = REPLACE(LEFT(@@SERVERNAME, CHARINDEX('\', @@SERVERNAME + '\') -1),'TRND52','TRND53'),
	@MaxBackupAgeHours int = 5, -- Max acceptable backup age in hours
	@SecondaryServer varchar(256) = '',
	@DB sysname,
	@Location nvarchar(2000),
	@SQL nvarchar(max),
	@BackupAgeMinutes int,
	@CurrentTime DATETIME2 = GETDATE(),
	@DirCmd nvarchar(4000),
	@GetFileAge varchar(8000),
	@Pattern1 nvarchar(256) = 'daily_TRAN_LOG_Backup_%',
	@Pattern2 nvarchar(256) = 'wknd_MAINT_%',
	@primaryFull sysname,
	@primaryBase sysname,
	@instance sysname,
	@rev nvarchar(255),
	@firstNonDigit int,
	@digits int,
	@prefix nvarchar(255),
	@numStr nvarchar(255),
	@secondaryBase nvarchar(255),
	@secondaryFull sysname,
	@xp int,
	@ps varchar(8000)

--Collect user databases to process	
IF OBJECT_ID('tempdb..#UserDBs') IS NOT NULL DROP TABLE #UserDBs;
CREATE TABLE #UserDBs 
(
	DBName sysname
);

--Loop per database, locate latest backup, validate age and restore
INSERT INTO #UserDBs (DBName)
SELECT name FROM sys.databases
WHERE name NOT IN ('master','model','msdb','tempdb','hsadmin')
	AND state_desc = 'ONLINE';
	--AND state_desc = 'OFFLINE';

WHILE EXISTS (SELECT 1 FROM #UserDBs)
BEGIN
	SELECT TOP 1 @DB = DBName 
	FROM #UserDBs 
	ORDER BY DBName;

	SET @Location = NULL;
	--Locate latest backup file (uses xp_cmdshell dir listing)
	IF EXISTS (	SELECT 1 
				FROM sys.configurations 
				WHERE name = 'xp_cmdshell' AND value =1)
	BEGIN
		CREATE TABLE #dir 
		(
			line nvarchar(4000)
		);
		SET @DirCmd = 'dir "' + @BasePath + @ServerTag + '\' + @DB + '\*_DR_Prod_FULL_part0.LBK" /b /o:-d';
		INSERT INTO #dir 
		EXEC xp_cmdshell @DirCmd;
		SELECT TOP 1 
			@Location = @BasePath + @ServerTag + '\' + @DB + '\' + line 
		FROM #dir 
		WHERE line IS NOT NULL and line <> '';
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

	--Check backup file age
	SET @BackupAgeMinutes = -1;
	--Compute Backup Age (Powershell Get-Item -> LastWriteTime)
	IF EXISTS(	SELECT 1 
				FROM sys.configurations 
				WHERE name = 'xp_cmdshell' AND value = 1)
	BEGIN
		CREATE TABLE #fileinfo 
		(
			info varchar(8000)
		);
		SET @GetFileAge = 'powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Test-Path ''' + @Location + ''') { $f = Get-Item ''' + @Location + '''; $age = [math]::Round(((Get-Date) - $f.LastWriteTime).TotalMinutes); Write-Output $age } else { Write-Output ''FILE_NOT_FOUND'' }"';
		INSERT INTO #fileinfo 
		EXEC xp_cmdshell @GetFileAge;
		SELECT TOP 1 
			@BackupAgeMinutes = TRY_CONVERT(int, info) 
		FROM #fileinfo 
		WHERE info NOT LIKE '%FILE_NOT_FOUND%' AND ISNUMERIC(info) = 1;
		DROP TABLE #fileinfo;
	END

	--Validate backup before restore
	--Ensure we skip stale backups older than @MaxBackipAgeHours
	IF @BackupAgeMinutes IS NOT NULL AND @BackupAgeMinutes >= 0
	BEGIN
		IF @BackupAgeMinutes > (@MaxBackupAgeHours * 60)
		BEGIN
			PRINT 'WARNING: Backup for ' + @DB + ' is ' + CAST(@BackupAgeMinutes / 60 AS NVARCHAR(10)) + ' hours old (max allowed: ' + CAST(@MaxBackupAgeHours AS NVARCHAR(10)) + '). Skipping restore.';
			DELETE FROM #UserDBs WHERE DBName = @DB
			CONTINUE;
		END
		ELSE
		BEGIN
			PRINT 'Backup for ' + @DB + ' is ' + CAST(@BackupAgeMinutes / 60.0 AS nvarchar(10)) + ' hours old. Proceeding with restore';
		END
	END
	ELSE
	BEGIN
		PRINT 'Warning: Could not determine backup age for ' + @DB + '.';
	END

	--Restore execution (uses stored procedure sp_Reload2_AG_DB)

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
	--Drop temp objects used for iteration
	--Cleanup temp table
	IF OBJECT_ID('tempdb..#UserDBs') IS NOT NULL DROP TABLE #UserDBs;


	--Enable Jobs after Restore
	--Ensure we are on PRIMARY and compute secondary server
	IF NOT EXISTS(	SELECT 1 
					FROM sys.dm_hadr_availability_replica_states 
					WHERE is_local = 1 AND role = 1)
	BEGIN
		PRINT 'This is not primary. Exiting.';
		RETURN;
	END

	SET @primaryFull = @@SERVERNAME;
	SET @primaryBase =
		CASE WHEN CHARINDEX('\', @primaryFull) > 0
			THEN LEFT(@primaryFull, CHARINDEX('\', @primaryFull) -1)
			ELSE @primaryFull
		END;
	
	SET @instance =
		CASE WHEN CHARINDEX('\', @primaryFull) > 0
			THEN SUBSTRING(@primaryFull, CHARINDEX('\', @primaryFull) +1, 255)
			ELSE NULL
		END;

	SET @rev = REVERSE(@primaryBase);
	SET @firstNonDigit = PATINDEX('%[^0-9]%', @rev);
	SET @digits = CASE WHEN @firstNonDigit = 0 THEN LEN(@primaryBase) ELSE @firstNonDigit - 1 END;
	SET @prefix = LEFT(@primaryBase, LEN(@primaryBase) - @digits);
	SET @numStr = RIGHT(@primaryBase, @digits);

	SET @secondaryBase =
		@prefix + RIGHT(REPLICATE('0', LEN(@numStr)) + CAST(CAST(@numStr as int) + 1 as nvarchar(50)), LEN(@numStr));

	SET @secondaryFull =
		CASE WHEN @instance IS NULL THEN @secondaryBase ELSE @secondaryBase + '\' + @instance END;
	
	--Confirm xp_cmdshell enabled before PowerShell call
	SET @xp = (	SELECT CAST(value_in_use as int) 
				FROM sys.configurations 
				WHERE name ='xp_cmdshell')
	IF @xp <> 1
			BEGIN
		PRINT 'xp_cmdshell disabled. Exiting';
		RETURN
	END

	--Enable matching jobs both Primary and Secondary
	SET @ps =
	N'powershell -NoProfile -ExecutionPolicy Bypass -Command "' +
	N'$primary = ''' + REPLACE(@primaryFull,'''','''''') + N'''; ' +
	N'$secondary = ''' + REPLACE(@secondaryFull,'''','''''') + N'''; ' +
	N'$pat1 = ''' + REPLACE(@Pattern1,'''','''''') + N'''; ' +
	N'$pat2 = ''' + REPLACE(@Pattern2,'''','''''') + N'''; ' +
	N'$sb = { param($server,$pat1,$pat2) ' +
	N'$cn = New-Object System.Data.SqlClient.SqlConnection(\"Server=$server;Integrated Security=true;\"); ' +
	N'$cn.Open(); ' +
	N'$cmd1 = New-Object System.Data.SqlClient.SqlCommand(\"SELECT name, enabled FROM msdb.dbo.sysjobs WHERE name LIKE @p\", $cn); ' +
	N'($cmd1.Parameters.Add(\"@p\", [System.Data.SqlDbType]::VarChar, 256)).Value = $pat1; ' +
	N'$r = $cmd1.ExecuteReader(); $jobs1 = @(); while ($r.Read()) { $jobs1 += [pscustomobject]@{ Name = $r.GetString(0); Enabled = ([int]$r.GetByte(1)) } } $r.Close(); ' +
	N'$cmd2 = New-Object System.Data.SqlClient.SqlCommand(\"SELECT name, enabled FROM msdb.dbo.sysjobs WHERE name LIKE @p\", $cn); ' +
	N'($cmd2.Parameters.Add(\"@p\", [System.Data.SqlDbType]::VarChar, 256)).Value = $pat2; ' +
	N'$r = $cmd2.ExecuteReader(); $jobs2 = @(); while ($r.Read()) { $jobs2 += [pscustomobject]@{ Name = $r.GetString(0); Enabled = ([int]$r.GetByte(1)) } } $r.Close(); ' +
	N'$jobs = @(); $seen = @{}; foreach ($j in ($jobs1 + $jobs2)) { if (-not $seen.ContainsKey($j.Name)) { $seen[$j.Name] = $true; $jobs += $j } } ' +
	N'foreach ($j in $jobs) { ' +
	N'if ($j.Enabled -eq 1) { Write-Host (\"Job is already enabled: \" + $server + \" : \" + $j.Name) } else { ' +
	N'$u = New-Object System.Data.SqlClient.SqlCommand(\"EXEC msdb.dbo.sp_update_job @job_name=@n, @enabled=1\", $cn); ($u.Parameters.Add(\"@n\", [System.Data.SqlDbType]::VarChar, 128)).Value = $j.Name; $u.ExecuteNonQuery() | Out-Null; ' +
	N'Write-Host (\"Job has been Enabled: \" + $server + \" : \" + $j.Name) } } $cn.Close(); }; ' +
	N'& $sb $primary $pat1 $pat2; ' +
	N'& $sb $secondary $pat1 $pat2"';

	--Execute PowerShell via xp_cmdshell
	EXEC xp_cmdshell @ps
	--PRINT @ps	
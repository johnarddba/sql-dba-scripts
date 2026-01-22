USE master;
GO

DECLARE
	@BasePath nvarchar(512) = '\\tshd53fsxot0001.hedgeservtest.com\rnd_db_tlogs\DR_Sync\',
	--@BasePath nvarchar(512) = N'\\hedgeservcustomers.com\shared\s3-db-backups\prd\DR_Sync\'
	@ServerTag nvarchar(128) = REPLACE(LEFT(@@SERVERNAME, CHARINDEX('\', @@SERVERNAME + '\') -1),'TRND52','TRND53'),
	@MaxBackupAgeHours int = 5, -- Max acceptable backup age in hours
	@SecondaryServer varchar(256) = '',
	@DB sysname,
	@Location nvarchar(2000),
	@SQL nvarchar(max),
	@BackupAgeMinutes int,
	@CurrentTime DATETIME2 = GETDATE()

IF OBJECT_ID('tempdb..#UserDBs') IS NOT NULL DROP TABLE #UserDBs;
CREATE TABLE #UserDBs (DBName sysname);

INSERT INTO #UserDBs (DBName)
SELECT name FROM sys.databases
WHERE name NOT IN ('master','model','msdb','tempdb','hsadmin')
AND state_desc = 'ONLINE';
--AND state_desc = 'OFFLINE';

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

	--Check backup file age
	SET @BackupAgeMinutes = -1;

	IF EXISTS(SELECT 1 FROM sys.configurations WHERE name = 'xp_cmdshell' AND value = 1)
	BEGIN
		CREATE TABLE #fileinfo (info varchar(8000));
		DECLARE @GetFileAge varchar(8000) = 'powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Test-Path ''' + @Location + ''') { $f = Get-Item ''' + @Location + '''; $age = [math]::Round(((Get-Date) - $f.LastWriteTime).TotalMinutes); Write-Output $age } else { Write-Output ''FILE_NOT_FOUND'' }"';
		INSERT INTO #fileinfo EXEC xp_cmdshell @GetFileAge;
		SELECT TOP 1 @BackupAgeMinutes = TRY_CONVERT(int, info) FROM #fileinfo WHERE info NOT LIKE '%FILE_NOT_FOUND%' AND ISNUMERIC(info) = 1;
		DROP TABLE #fileinfo;
	END

	--Validate backup before restore
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


--Enable Jobs after Restore

--DECLARE 
--	@JobPattern1 nvarchar(128) = N'wknd_MAINT%',
--	@JobPattern2 nvarchar(128) = N'daily_TRAN_LOG%'

--IF OBJECT_ID('tempdb..#EnableJobs') IS NOT NULL DROP TABLE #EnableJobs;
--CREATE TABLE #EnableJobs (job_name sysname)

--INSERT INTO #EnableJobs (job_name)
--SELECT  name FROM msdb.dbo.sysjobs
--WHERE (name LIKE @JobPattern1 OR name LIKE @JobPattern2)
--and enabled = 0;

--IF EXISTS (SELECT 1 FROM #EnableJobs)
--BEGIN
--	DECLARE @EnableJobSQL nvarchar(max) = N'';
--	SELECT @EnableJobSQL += N'EXEC msdb.dbo.sp_update_job @job_name = N''' + job_name + N''', @enabled = 1; '
--	FROM #EnableJobs;
--	PRINT @EnableJobSQL;
--	--EXEC @EnableJobSQL;
--END
--ELSE
--BEGIN
--	PRINT 'No matching disabled jobs found!';
--END

--DROP TABLE #EnableJobs



DECLARE
	@Pattern1 nvarchar(256) = 'daily_TRAN_LOG_Backup_%',
	@Pattern2 nvarchar(256) = 'wknd_MAINT_%'

IF NOT EXISTS(SELECT 1 FROM sys.dm_hadr_availability_replica_states WHERE is_local = 1 AND role = 1)
BEGIN
	PRINT 'This is not primary. Exiting.';
	RETURN;
END

	DECLARE @primaryFull sysname = @@SERVERNAME;
	DECLARE @primaryBase sysname =
		CASE WHEN CHARINDEX('\', @primaryFull) > 0
			THEN LEFT(@primaryFull, CHARINDEX('\', @primaryFull) -1)
			ELSE @primaryFull
		END;
	
	DECLARE @instance sysname =
		CASE WHEN CHARINDEX('\', @primaryFull) > 0
			THEN SUBSTRING(@primaryFull, CHARINDEX('\', @primaryFull) +1, 255)
			ELSE NULL
		END;

	DECLARE @rev nvarchar(255) = REVERSE(@primaryBase);
	DECLARE @firstNonDigit int = PATINDEX('%[^0-9]%', @rev);
	DECLARE @digits int = CASE WHEN @firstNonDigit = 0 THEN LEN(@primaryBase) ELSE @firstNonDigit - 1 END;
	DECLARE @prefix nvarchar(255) = LEFT(@primaryBase, LEN(@primaryBase) - @digits);
	DECLARE @numStr nvarchar(255) = RIGHT(@primaryBase, @digits);

	DECLARE @secondaryBase nvarchar(255) =
		@prefix + RIGHT(REPLICATE('0', LEN(@numStr)) + CAST(CAST(@numStr as int) + 1 as nvarchar(50)), LEN(@numStr));

	DECLARE @secondaryFull sysname=
		CASE WHEN @instance IS NULL THEN @secondaryBase ELSE @secondaryBase + '\' + @instance END;

	DECLARE @xp int = (SELECT CAST(value_in_use as int) FROM sys.configurations WHERE name ='xp_cmdshell')
		IF @xp <> 1
		BEGIN
			PRINT 'xp_cmdshell disabled. Exiting';
			RETURN
		END
			   
	--Checking
	--SELECT @primaryFull as '@primaryFull'
	--SELECT @primaryBase as '@primaryBase'
	--SELECT @rev as '@rev'
	--SELECT @firstNonDigit as '@firstNonDigit'
	--SELECT @digits as '@digits'
	--SELECT @prefix as '@prefix'
	--SELECT @numStr as '@numStr'
	--SELECT @secondaryBase as '@secondaryBase'
	--SELECT @xp as '@xp'
	--SELECT @instance as '@instance'
	--SELECT @secondaryFull as '@secondaryFull'


	DECLARE @ps varchar(8000) =
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
--N'Write-Host (\"Pattern1 jobs on \" + $server + \": \" + (($jobs1 | ForEach-Object {$_.Name}) -join \",\")); ' +
--N'Write-Host (\"Pattern2 jobs on \" + $server + \": \" + (($jobs2 | ForEach-Object {$_.Name}) -join \",\")); ' +
N'$jobs = @(); $seen = @{}; foreach ($j in ($jobs1 + $jobs2)) { if (-not $seen.ContainsKey($j.Name)) { $seen[$j.Name] = $true; $jobs += $j } } ' +
N'foreach ($j in $jobs) { ' +
N'if ($j.Enabled -eq 1) { Write-Host (\"Job is already enabled: \" + $server + \" : \" + $j.Name) } else { ' +
N'$u = New-Object System.Data.SqlClient.SqlCommand(\"EXEC msdb.dbo.sp_update_job @job_name=@n, @enabled=1\", $cn); ($u.Parameters.Add(\"@n\", [System.Data.SqlDbType]::VarChar, 128)).Value = $j.Name; $u.ExecuteNonQuery() | Out-Null; ' +
N'Write-Host (\"Job has been Enabled: \" + $server + \" : \" + $j.Name) } } $cn.Close(); }; ' +
N'& $sb $primary $pat1 $pat2; ' +
N'& $sb $secondary $pat1 $pat2"';

--N'powershell -NoProfile -ExecutionPolicy Bypass -Command "' +
--N'$primary = ''' + REPLACE(@primaryFull,'''','''''') + N'''; ' +
--N'$secondary = ''' + REPLACE(@secondaryFull,'''','''''') + N'''; ' +
--N'$pat1 = ''' + REPLACE(@Pattern1,'''','''''') + N'''; ' +
--N'$pat2 = ''' + REPLACE(@Pattern2,'''','''''') + N'''; ' +
--N'$sb = { param($server,$pat1,$pat2) ' +
--N'$cn = New-Object System.Data.SqlClient.SqlConnection(\"Server=$server;Integrated Security=true;\"); ' +
--N'$cn.Open(); ' +
--N'$cmd = New-Object System.Data.SqlClient.SqlCommand(\"SELECT name FROM msdb.dbo.sysjobs WHERE name LIKE @p1 OR name LIKE @p2\", $cn); ' +
--N'($cmd.Parameters.Add(\"@p1\", [System.Data.SqlDbType]::VarChar, 256)).Value = $pat1; ' +
--N'($cmd.Parameters.Add(\"@p2\", [System.Data.SqlDbType]::VarChar, 256)).Value = $pat2; ' +
--N'$cmd.CommandText = \"SELECT name, enabled FROM msdb.dbo.sysjobs WHERE name LIKE @p1 OR name LIKE @p2\"; ' +
--N'$r = $cmd.ExecuteReader(); $jobs = @(); while ($r.Read()) { $jobs += [pscustomobject]@{ Name = $r.GetString(0); Enabled = ([int]$r.GetByte(1)) } } $r.Close(); ' +
--N'foreach ($j in $jobs) { ' +
--N'if ($j.Enabled -eq 1) { Write-Host (\"Already enabled: \" + $server + \" : \" + $j.Name) } else { ' +
--N'$u = New-Object System.Data.SqlClient.SqlCommand(\"EXEC msdb.dbo.sp_update_job @job_name=@n, @enabled=1\", $cn); ($u.Parameters.Add(\"@n\", [System.Data.SqlDbType]::VarChar, 128)).Value = $j.Name; $u.ExecuteNonQuery() | Out-Null; ' +
--N'Write-Host (\"Enabled: \" + $server + \" : \" + $j.Name) } } $cn.Close(); }; ' +
----N'$j1 = Start-Job -ScriptBlock $sb -ArgumentList $primary,$pat1,$pat2; ' +
----N'$j2 = Start-Job -ScriptBlock $sb -ArgumentList $secondary,$pat1,$pat2; ' +
----N'Wait-Job -Id $j1.Id,$j2.Id | Receive-Job"'
--N'& $sb $primary $pat1 $pat2; ' +
--N'& $sb $secondary $pat1 pat2"';
	
	EXEC xp_cmdshell @ps
	--PRINT @ps





USE master;
GO

DECLARE
	@BasePath nvarchar(512) = '\\shared\',
	@ServerTag nvarchar(128) = REPLACE(LEFT(@@SERVERNAME, CHARINDEX('\', @@SERVERNAME + '\') -1),'TRND52','TRND53'),
	@DB sysname,
	@Location nvarchar(2000),
	@SQL nvarchar(max)

IF OBJECT_ID('tempdb..#UserDBs') IS NOT NULL DROP TABLE #UserDBs;
CREATE TABLE #UserDBs (DBName sysname);

INSERT INTO #UserDBs (DBName)
SELECT name FROM sys.databases
WHERE name NOT IN ('master','model','msdb','tempdb','hsadmin')
AND state_desc = 'ONLINE';

WHILE EXISTS (SELECT 1 FROM #UserDBs)
BEGIN
	SELECT TOP 1 @DB = DBName FROM #UserDBs ORDER BY DBName;
	-- Try to find the actual LiteSpeed part0 file in the DB folder (uses xp_cmdshell if enabled)
	SET @Location = NULL;
	IF EXISTS (SELECT 1 FROM sys.configurations WHERE name = 'xp_cmdshell' AND value = 1)
	BEGIN
		CREATE TABLE #dir (line nvarchar(4000));
		DECLARE @DirCmd NVARCHAR(4000) = 'dir "' + @BasePath + @ServerTag + '\\' + @DB + '\\*_DR_Prod_FULL_part0.LBK" /b /o:-d';
		INSERT INTO #dir EXEC xp_cmdshell @DirCmd;
		SELECT TOP 1 @Location = @BasePath + @ServerTag + '\\' + @DB + '\\' + line FROM #dir WHERE line IS NOT NULL AND line <> '';
		DROP TABLE #dir;
	END
	ELSE
	BEGIN
		PRINT 'xp_cmdshell is disabled; falling back to constructed filename';
	END
	-- Fallback if not found
	IF @Location IS NULL
	BEGIN
		SET @Location = @BasePath + @ServerTag + '\\' + @DB + '\\' + @ServerTag + '_' + @DB + '_' + 'DR_Prod_FULL_part0.LBK';
	END
	PRINT 'use master; EXEC sp_Reload2_AG_DB @DBNAME=''' + @DB + ''', @LOCATION=''' + @Location + '''';
	BEGIN TRY
		SET @SQL = N'use master; EXEC sp_Reload2_AG_DB @DBNAME=@db, @LOCATION=@loc';
		EXEC sp_executesql
			@SQL,
			N'@db sysname, @loc nvarchar(2000)',
			@db = @DB,
			@loc = @Location;
	END TRY
	BEGIN CATCH
		PRINT 'Error in ' + @DB + ': ' + ERROR_MESSAGE();
	END CATCH

	DELETE FROM #UserDBs WHERE DBName = @DB;
END

IF OBJECT_ID('tempdb..#UserDBs') IS NOT NULL DROP TABLE #UserDBs;
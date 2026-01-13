--Backup DR Database and set offline

DECLARE
	@BackupFolder nvarchar(255) = N'\\tshd53fsxot0001.hedgeservtest.com\rnd_db_tlogs\DR_Sync\',
	@Servername nvarchar(255) = SUBSTRING(@@SERVERNAME, 1, CHARINDEX('\', @@SERVERNAME) - 1),
	@CurrentDB nvarchar(128),
	@F0 nvarchar(max),
	@F1 nvarchar(max),
	@F2 nvarchar(max),
	@F3 nvarchar(max),
	@F4 nvarchar(max)

IF OBJECT_ID('tempdb..#DBList') IS NOT NULL DROP TABLE #DBList;
CREATE TABLE #DBList(DBName nvarchar(128));

INSERT INTO #DBList (DBName)

SELECT name FROM sys.databases
WHERE name NOT IN ('master','tempdb','model','msdb','hsadmin')
AND state_desc = 'online';

WHILE EXISTS (SELECT 1 FROM #DBList)
BEGIN

	SELECT TOP 1 @CurrentDB = DBName FROM #DBList
	SET @F0 = @BackupFolder + @Servername + '_' + @CurrentDB + '_' + 'DR_Prod_FULL' + '_part0.LBK';
	SET @F1 = @BackupFolder + @Servername + '_' + @CurrentDB + '_' + 'DR_Prod_FULL' + '_part1.LBK';
	SET @F2 = @BackupFolder + @Servername + '_' + @CurrentDB + '_' + 'DR_Prod_FULL' + '_part2.LBK';
	SET @F3 = @BackupFolder + @Servername + '_' + @CurrentDB + '_' + 'DR_Prod_FULL' + '_part3.LBK';
	SET @F4 = @BackupFolder + @Servername + '_' + @CurrentDB + '_' + 'DR_Prod_FULL' + '_part4.LBK';

	BEGIN TRY
		EXEC master.dbo.xp_backup_database
			@database = @CurrentDB,
			@filename = @F0,
			@filename = @F1,
			@filename = @F2,
			@filename = @F3,
			@filename = @F4,
			@backupname = @CurrentDB,
			@desc = 'Full Backup of DR database',
			@compressionlevel = 5,
			@init = 1,
			@with = N'SKIP',
			@with = N'STATS = 10';

		-- Put database offline after successful backup (only if ONLINE)
		DECLARE @OfflineSQL NVARCHAR(MAX) = N'ALTER DATABASE ' + QUOTENAME(@CurrentDB) + N' SET OFFLINE WITH ROLLBACK IMMEDIATE;';
		IF EXISTS (SELECT 1 FROM sys.databases WHERE name = @CurrentDB AND state_desc = 'ONLINE')
		BEGIN
			PRINT 'Setting database ' + QUOTENAME(@CurrentDB) + ' OFFLINE';
			EXEC(@OfflineSQL);
		END
		ELSE
		BEGIN
			PRINT 'Skipping setting ' + QUOTENAME(@CurrentDB) + ' offline because it is not ONLINE';
		END

		END TRY
	BEGIN CATCH
		PRINT 'Error backing up ' + @CurrentDB + ': ' + ERROR_MESSAGE();	
	END CATCH

	DELETE FROM #DBList WHERE DBName = @CurrentDB;

END

--Delete temp table
IF OBJECT_ID('tempdb..#DBList') IS NOT NULL DROP TABLE #DBList;
GO



























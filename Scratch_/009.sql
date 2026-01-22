--Backup DR Database and set offline
DECLARE
	@BackupFolder nvarchar(255) = N'\\tshd53fsxot0001.hedgeservtest.com\rnd_db_tlogs\DR_Sync\',
	--@BackupFolder nvarchar(255) = N'\\hedgeservcustomers.com\shared\s3-db-backups\prd\DR_Sync\',
	@SQL nvarchar(255),
	@Servername nvarchar(255) = SUBSTRING(@@SERVERNAME, 1, CHARINDEX('\', @@SERVERNAME) - 1),
	@CurrentDB nvarchar(128),
	@F0 nvarchar(max),
	@F1 nvarchar(max),
	@F2 nvarchar(max),
	@F3 nvarchar(max),
	@F4 nvarchar(max),
	@dt datetime = getdate(),
	@wkYear varchar(4) =(SELECT DATEPART(ww, getdate())),
	@o varchar(50)
	
SELECT @o = CONVERT(nvarchar(4),DATEPART(yyyy,@dt))+RIGHT('0'+CONVERT(nvarchar(2),DATEPART(mm,@dt)),2)+RIGHT('0'+CONVERT(nvarchar(2),DATEPART(dd,@dt)),2)+RIGHT('0'+CONVERT(nvarchar(2),DATEPART(hh,@dt)),2)+RIGHT('0'+CONVERT(nvarchar(2),DATEPART(mi,@dt)),2)

IF OBJECT_ID('tempdb..#DBList') IS NOT NULL DROP TABLE #DBList;
CREATE TABLE #DBList(DBName nvarchar(128));

INSERT INTO #DBList (DBName)
SELECT name FROM sys.databases
WHERE name NOT IN ('master','tempdb','model','msdb','hsadmin')
AND state_desc = 'online';

WHILE EXISTS (SELECT 1 FROM #DBList)
BEGIN

	SELECT TOP 1 @CurrentDB = DBName FROM #DBList
	
	SET @F0 = @BackupFolder + '\' + @Servername + '\' + @CurrentDB + '\' + 'wk_'+ @wkYear + '_' + DATENAME(dw, GETDATE()) + '_'+@o + '_' + @CurrentDB  + '_' + 'DR_Prod_FULL' + '_part0.LBK';
	SET @F1 = @BackupFolder + '\' + @Servername + '\' + @CurrentDB + '\' + 'wk_'+ @wkYear + '_' + DATENAME(dw, GETDATE()) + '_'+@o + '_' + @CurrentDB  + '_' + 'DR_Prod_FULL' + '_part1.LBK';
	SET @F2 = @BackupFolder + '\' + @Servername + '\' + @CurrentDB + '\' + 'wk_'+ @wkYear + '_' + DATENAME(dw, GETDATE()) + '_'+@o + '_' + @CurrentDB  + '_' + 'DR_Prod_FULL' + '_part2.LBK';
	SET @F3 = @BackupFolder + '\' + @Servername + '\' + @CurrentDB + '\' + 'wk_'+ @wkYear + '_' + DATENAME(dw, GETDATE()) + '_'+@o + '_' + @CurrentDB  + '_' + 'DR_Prod_FULL' + '_part3.LBK';
	SET @F4 = @BackupFolder + '\' + @Servername + '\' + @CurrentDB + '\' + 'wk_'+ @wkYear + '_' + DATENAME(dw, GETDATE()) + '_'+@o + '_' + @CurrentDB  + '_' + 'DR_Prod_FULL' + '_part4.LBK';

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

		--Bring database offline after each successfull backup
		SET @SQL = N'ALTER DATABASE ' + '[' + @CurrentDB + ']' + N' SET OFFLINE WITH ROLLBACK IMMEDIATE;';
		--PRINT @SQL
		EXEC(@SQL)
		
		END TRY
	BEGIN CATCH
		PRINT 'Error backing up ' + @CurrentDB + ': ' + ERROR_MESSAGE();	
	END CATCH

	DELETE FROM #DBList WHERE DBName = @CurrentDB;

END

--Delete temp table
IF OBJECT_ID('tempdb..#DBList') IS NOT NULL DROP TABLE #DBList;
GO





















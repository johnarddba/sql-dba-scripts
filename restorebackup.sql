USE [master]
GO

/****** Object:  StoredProcedure [dbo].[sp_Reload2_AG_DB_test]    Script Date: 1/7/2026 3:32:46 AM ******/
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO







--CREATE PROCEDURE [dbo].[sp_Reload2_AG_DB_test]
--(  
--@DBNAME VARCHAR(60),  
--@BackupName VARCHAR(500)
--)  
--AS 
--SET NOCOUNT ON  
--SET CONCAT_NULL_YIELDS_NULL OFF  
 
--BEGIN TRY

DECLARE 
@DBNAME VARCHAR(60),      
@BackupName VARCHAR(100),


    @DataFilePath VARCHAR (255),
    @LogFilePath VARCHAR(255),
    @JobName varchar (100),
    @ServerName NVARCHAR(256)  = @@SERVERNAME,
    @NodeName   VARCHAR(32) = CONVERT(VARCHAR, SERVERPROPERTY('ComputerNamePhysicalNetBIOS')), 
    @DataDrive CHAR(1), 
    @BackupDrive  CHAR(1),
    @AGname varchar(255),
    @RoleDesc NVARCHAR(60),
    @SQL varchar(1024)

SELECT @AGname = ag.name
  FROM [master].[sys].[availability_databases_cluster] ad
  join [sys].[availability_groups] ag
  on ad.group_id=ag.group_id
  where ad.database_name= @DBNAME

SELECT @RoleDesc=A.role_desc
    FROM sys.dm_hadr_availability_replica_states AS a
  JOIN sys.availability_replicas AS b
        ON b.replica_id = a.replica_id
    JOIN sys.availability_groups AS C
        ON C.group_id = a.group_id
WHERE b.replica_server_name = @@SERVERNAME
AND C.NAME = @AGname

IF  @RoleDesc = 'PRIMARY'
BEGIN
SELECT DISTINCT  @DataDrive = LEFT(physical_name, 1), @DataFilePath =   physical_name
FROM master.sys.master_files 
where database_id=DB_ID(@DBNAME) and type = 0
SELECT DISTINCT  @BackupDrive = LEFT(physical_name, 1),   @LogFilePath = physical_name
FROM master.sys.master_files 
where database_id=DB_ID(@DBNAME) and type = 1

DECLARE  @B_file_list TABLE (
LogicalName nvarchar(4000),
PhysicalName nvarchar(4000),
Type nvarchar(4000),
FileGroupName nvarchar(4000),
Size nvarchar(4000),
MaxSize nvarchar(4000),
FileId nvarchar(4000),
BackupSizeInBytes nvarchar(4000),
FileGroupId nvarchar(4000))

INSERT @B_file_list EXEC master.dbo.xp_restore_filelistonly @filename=@BackupName

DECLARE @WITH1 VARCHAR(MAX), @WITH2 VARCHAR(MAX)

SELECT @WITH1 = 'MOVE ''''' + LOGICALNAME + ''''' TO ''''' + @DataFilePath + '''''' FROM @B_file_list WHERE Type = 'D'

SELECT @WITH2 = 'MOVE ''''' + LOGICALNAME + ''''' TO ''''' + @LogFilePath + '''''' FROM @B_file_list WHERE Type = 'L'

SET @SQL =''
SET @SQL = 'use master ALTER AVAILABILITY GROUP [' + @AGname + '] REMOVE DATABASE [' + @DBNAME + ']'
PRINT @SQL
--EXEC (@SQL)
SET @SQL =''
SET @SQL = 'use master ALTER DATABASE [' + @DBNAME + '] SET OFFLINE WITH ROLLBACK IMMEDIATE'
PRINT @SQL
--EXEC (@SQL)
DECLARE @RestoreSQL varchar (8000)

IF (@BackupName  like '%PART%')
BEGIN
DECLARE @BackupName0 nvarchar(300)
DECLARE @BackupName1 nvarchar(300)
DECLARE @BackupName2 nvarchar(300)
DECLARE @BackupName3 nvarchar(300)
DECLARE @BackupName4 nvarchar(300)

SET @BackupName0 = replace(@BackupName,substring(@BackupName,charindex('part',@BackupName),5),'PART0')
SET @BackupName1 = replace(@BackupName0 ,'PART0','PART1')
SET @BackupName2 = replace(@BackupName0 ,'PART0','PART2')
SET @BackupName3 = replace(@BackupName0 ,'PART0','PART3')
SET @BackupName4 = replace(@BackupName0 ,'PART0','PART4')

--PRINT 'Multiple Files'

SET @RestoreSQL = 'exec master.dbo.xp_restore_database @database = ''' 
+@DBNAME 
+ ''', @filename = '''
+@BackupName0
+ ''', @filename = '''
+@BackupName1
+ ''', @filename = '''
+@BackupName2
+ ''', @filename = '''
+@BackupName3
+ ''', @filename = '''
+@BackupName4
+''', @with = ''' 
+@WITH1
+''', @with = ''' 
+@WITH2
+''', @with = ''RECOVERY'', @ioflag=N''OVERLAPPED'', @with = ''NOUNLOAD'', @with = ''STATS = 10'', @with = ''REPLACE'', @logging = 0'
--PRINT @RestoreSQL
EXEC (@RestoreSQL)

END

ELSE

BEGIN
--PRINT 'Single File'

SET @RestoreSQL = 'exec master.dbo.xp_restore_database @database = ''' 
+@DBNAME 
+ ''', @filename = '''
+@BackupName
+''', @with = ''' 
+@WITH1+''', @with = ''' 
+@WITH2+''', @with = ''RECOVERY'', @with = ''NOUNLOAD'', @with = ''STATS = 10'', @with = ''REPLACE'', @logging = 0'
--PRINT @RestoreSQL
EXEC (@RestoreSQL)
END

SET @SQL =''
SET @SQL = 'use [' + @DBNAME + '] EXEC sp_changedbowner sa '
PRINT @SQL
--EXEC (@SQL)
SET @SQL =''
SET @SQL = 'use [' + @DBNAME + ']  execute sp_resync_users '
PRINT @SQL
----EXEC (@SQL)
SET @SQL =''
SET @SQL = 'use master ALTER DATABASE [' + @DBNAME + '] SET RECOVERY Full'
PRINT @SQL
--EXEC (@SQL)

select @SQL = ''
select @SQL = 'IF exists  (select name from sys.databases where name = '''+ @DBName + ''' and state_desc=''ONLINE'') alter database [' + @DBName + '] SET COMPATIBILITY_LEVEL = 150'
PRINT @SQL
exec(@SQL)

SET @SQL =''
SET @SQL = 'use master ALTER AVAILABILITY GROUP [' + @agname + '] ADD DATABASE [' + @DBNAME + ']  '
PRINT @SQL
--EXEC (@SQL)

SET @BackupName = '\\'+@NodeName+'\backup\' +@DBNAME+'.lbk'

SET @SQL =''
SET @SQL ='exec master.dbo.xp_backup_database                          @database=''' +@DBNAME + ''',                                @filename='''+@BackupName+''',                            @init = 1,             @logging = 0, @CompressionLevel=5, @ioflag=N''OVERLAPPED'',   @with = N''COPY_ONLY'',@with = N''SKIP'', @with = N''STATS = 10'''
PRINT @SQL
--EXEC (@SQL)

DECLARE @Replica VARCHAR(MAX)

SELECT @Replica = MIN(AR.[replica_server_name])
  FROM [master].[sys].[availability_replicas] AR
  JOIN [master].[sys].[availability_groups] AG
  ON AR.group_id=AG.group_id
WHERE AG.NAME=@agname AND AR.[replica_server_name] <>@@SERVERNAME

WHILE @Replica IS NOT NULL
BEGIN
SET @RestoreSQL = 'exec master.dbo.xp_restore_database @database = ''' +@DBNAME + ''', @filename = '''+@BackupName+''', @with = ''' +@WITH1+''', @with = ''' +@WITH2+''', @with = ''NORECOVERY'', @with = ''NOUNLOAD'', @with = ''STATS = 10'', @with = ''REPLACE'', @logging = 0'

SET @SQL =''
SET @SQL = 'sqlcmd.exe -S' + @Replica + ' -E -Q "' +@RestoreSQL +'; ALTER DATABASE ['+@DBNAME + '] SET HADR AVAILABILITY GROUP = [' +@agname +'];"'
PRINT @SQL
EXECUTE xp_cmdshell @SQL

SELECT @Replica = MIN(AR.[replica_server_name])
  FROM [master].[sys].[availability_replicas] AR
  JOIN [master].[sys].[availability_groups] AG
  ON AR.group_id=AG.group_id
WHERE AG.NAME=@agname AND AR.[replica_server_name] <>@@SERVERNAME AND AR.[replica_server_name]>@Replica

END
END
ELSE
PRINT 'THIS IS SECONDARY SERVER'

--END TRY  
--BEGIN CATCH

--/*ANDREW`S CODE*/
--DECLARE @ErrorMessage NVARCHAR(1024), @ErrMessage NVARCHAR(1024),@ErrorNumber INT, @ErrorSeverity INT, @ErrorState INT, @ErrorLine INT, @ErrorProcedure NVARCHAR(256);  
--  SELECT   @ErrorNumber = ERROR_NUMBER(),  
--           @ErrorSeverity = ERROR_SEVERITY(),  
--           @ErrorState = ERROR_STATE(),  
--           @ErrorLine = ERROR_LINE(),  
--           @ErrorProcedure = ISNULL(ERROR_PROCEDURE(), '');  
--  SELECT @ErrorMessage = N'Error %d, Level %d, State %d, PROCEDURE %s, Line %d, Message: ' + ERROR_MESSAGE();  
--  SET @ErrMessage = ERROR_MESSAGE()  
--  DECLARE @err_rcps varchar(255), @err_rcps1 varchar(255), @err_bdy varchar(255), @err_Subject VARCHAR (512)  
--  SET @err_rcps='IT-DBA@hedgeserv.com'  
--SET @err_Subject='Reload for ' + @DBNAME + ' has failed on ' +@@SERVERNAME  
--SET @err_bdy = 'Reload for  ' + @DBNAME + ' has failed on ' +@@SERVERNAME  
--   EXEC msdb.dbo.sp_sEND_dbmail  
--@profile_name = 'IT-DBA NotIFication',  
--@recipients = @err_rcps,  
--@subject = @err_Subject,  
--@body = @err_bdy,  
--@body_format = 'HTML'   
--  RAISERROR(@ErrorMessage, @ErrorSeverity, 1, @ErrorNumber, @ErrorSeverity, @ErrorState, @ErrorProcedure, @ErrorLine)  
 
--END CATCH
GO



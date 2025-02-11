--Backup Scripts for SQL Server with litespeed

/**** Full Backup ****/
execute master.dbo.xp_backup_database  
@database = 'database name',  
@filename = 'Backup path\backup file name.bak',  
@init = 1,  
@compressionlevel = 4

/**** Differential Backup ****/
execute master.dbo.xp_backup_database 
@database = 'database name', 
@filename = 'Backup path\backup file name.bak', 
@init = 1,  @compressionlevel = 4, 
@with =  differential

/**** Transaction Log Backup ****/
execute master.dbo.xp_backup_log 
@database = 'database name', 
@filename = 'Backup path\backup file name.trn', 
@init = 1,  @compressionlevel = 4

/**** Filegroup Backup ****/
execute master.dbo.xp_backup_database  
@database = 'database name', 
@filename = 'Backup path\backup file name.bck', 
@init = 1,
@compressionlevel = 4, 
@filegroup = 'filegroupname'


--Restore Scripts for SQL Server with litespeed


/**** Script to check the data and log file information from backup file ****/
exec master.dbo.xp_restore_filelistonly
@filename ='BackupPath\BackupFileName.bak'
GO

/**** Script to check the backup file header information ****/
exec master.dbo.xp_restore_headeronly
@filename ='BackupPath\BackupFileName.bak'
GO

/**** Script to check if the backup file is valid or not ****/
EXEC master.dbo.xp_restore_verifyonly
@filename ='BackupPath\BackupFileName.bak' 
GO

/**** Script to restore database using Full backup with the default options ****/
exec master.dbo.xp_restore_database
@database = 'dbname',
@filename = 'BackupPath\BackupFileName.bak'
GO

/**** Script to restore database using Full backup with file move option ****/
exec master.dbo.xp_restore_database
@database = 'dbname',
@filename = 'BackupPath\BackupFileName.bak',
@with = 'move "logical filename" to "physical file location.mdf"',
@with = 'move "logical filename" to "physical file location.ldf"' 
GO

/**** Script to restore database using Full backup with replace option ****/
exec master.dbo.xp_restore_database
@database = 'dbname',
@filename = 'BackupPath\BackupFileName.bak',
@with = 'replace', @with = 'move "logical filename" to "physical file location.mdf"',
@with = 'move "logical filename" to "physical file location.ldf"'
GO

/**** Script to restore Full backup with no recovery ****/
exec master.dbo.xp_restore_database
@database = 'dbname',
@filename = 'BackupPath\BackupFileName.bak',
@with = 'replace', @with = 'move "logical filename" to "physical file location.mdf"',
@with = 'move "logical filename" to "physical file location.ldf"',
@with='NORECOVERY' 
GO

/**** Script to restore log backup with no recovery ****/
EXEC master.dbo.xp_restore_log
@database = 'dbname',
@filename = 'BackupPath\BackupFileName.trn',
@with ='NORecovery' 
GO

/**** Script to restore log backup with recovery ****/
EXEC master.dbo.xp_restore_log
@database = 'dbname',
@filename = 'BackupPath\BackupFileName.trn',
@with ='Recovery' 
GO

/**** Script to do point in time recovery ****/
EXEC master.dbo.xp_restore_log
 @database = 'dbname',
 @filename = 'BackupPath\BackupFileName.trn',
 @with ='Recovery',
 @with = 'STOPBEFOREMARK = LogMark'
GO


/**** Script to do restore split backup ****/

 exec master.dbo.xp_restore_database @database = N'hshiluxprod9000' ,
@filename = N'E:\Backup\wk_7_Monday_202502101841_Full_hshiluxprod9000_part0.LBK',
@filename = N'E:\Backup\wk_7_Monday_202502101841_Full_hshiluxprod9000_part1.LBK',
@filename = N'E:\Backup\wk_7_Monday_202502101841_Full_hshiluxprod9000_part2.LBK',
@filename = N'E:\Backup\wk_7_Monday_202502101841_Full_hshiluxprod9000_part3.LBK',
@filename = N'E:\Backup\wk_7_Monday_202502101841_Full_hshiluxprod9000_part4.LBK',
@filenumber = 1,
@with = N'STATS = 10',
@with = N'STANDBY = N''E:\DBBackup\PROD\UNDO\hshiluxprod9000_undo.TUF''',
@affinity = 0,
@logging = 0
 
 
GO
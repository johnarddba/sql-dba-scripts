DECLARE
	@sharedFolder nvarchar(4000) = 'E:\Backup',
	@newFolderName nvarchar(255) = 'mainFolder',
	@subFolder1 varchar(255) = 'folder1',
	@subFolder2 varchar(255) = 'folder2',
	@subFolder3 varchar(255) = 'folder3',
	@cmd nvarchar(4000),
	@jobName sysname = N''
	
DECLARE	@BasePath nvarchar(4000) =
		@sharedFolder
		+ CASE WHEN RIGHT(@sharedFolder, 1) IN ('\','/')
			THEN N''
			ELSE N'\'
		  END
		+ @newFolderName
	
SET @cmd =
	N'cmd/c '+
	N'mkdir "' + REPLACE(@BasePath, '"', '""') + N'" ' +
	N'"' + REPLACE(@BasePath + N'\' + @subFolder1, '"', '""') + N'" ' +
	N'"' + REPLACE(@BasePath + N'\' + @subFolder2, '"', '""') + N'" ' +	
	N'"' + REPLACE(@BasePath + N'\' + @subFolder3, '"', '""') + N'" ';

EXEC master.dbo.xp_cmdshell @cmd;

EXEC msdb.dbo.sp_start_job @job_name = @jobName;




-- This script verifies the integrity of a backup file without restoring it.
-- It checks if the backup file is valid and can be used for restoration.
use master;
go

RESTORE VERIFYONLY
FROM DISK = 'C:\SQL_2022\BACKUP\AdventureWorks2022.bak'
WITH CHECKSUM;

GO

--DECLARE @BackupFilePath NVARCHAR(500) = 'C:\SQL_2022\BACKUP\AdventureWorks2022.bak'
DECLARE @BackupFilePath NVARCHAR(500) = 'C:\SQL_2022\BACKUP\_TSQL.bak'
DECLARE @ReturnCode INT;

BEGIN TRY
	--
	RESTORE VERIFYONLY
	FROM DISK = @BackupFilePath
	WITH CHECKSUM;

	SET @ReturnCode = @@ERROR;

	IF @ReturnCode = 0
		PRINT 'Backup verification sucessfull: The backup file is valid and complete.';
	ELSE
		PRINT 'Backup verification failed: Error code' + CAST(@ReturnCode AS NVARCHAR(10))
END TRY
BEGIN CATCH
	PRINT 'Error during backup verification:';
	PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10));
	PRINT 'Error Message: ' + ERROR_MESSAGE();
END CATCH;

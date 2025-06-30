DECLARE @DaysToKeep INT = 30;
DECLARE @CutoffDate DATETIME = DATEADD(DAY, -@DaysToKeep, GETDATE());

BEGIN TRY
	EXEC msdb.dbo.sp_delete_backuphistory @oldest_date = @CutoffDate;
	PRINT 'Old backup history sucessfully cleaned for older backups older than ' + CAST(@DaysToKeep AS NVARCHAR(10)) + ' days.';
END TRY
BEGIN CATCH
	PRINT 'Error during backup cleanup:';
	PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10));
	PRINT 'Error Message: ' + ERROR_MESSAGE();

END CATCH;

-- Extract Server Name without the instance

DECLARE @serverName VARCHAR(50) ;
SET @serverName = SUBSTRING(@@SERVERNAME, 1, CHARINDEX('\', @@SERVERNAME) -1);

SELECT @serverName AS [Server Name]
--PRINT @serverName

GO
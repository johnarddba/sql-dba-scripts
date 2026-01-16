DECLARE 
	@PrimaryServer nvarchar(255) = LEFT(@@SERVERNAME, CHARINDEX('\', @@SERVERNAME + '\') -1),
	

	SELECT @PrimaryServer
        AS [Primary Server Name Without Instance]

BEGIN

DECLARE
    @dt datetime,
    @0 varchar(50),
    @dtt varchar(100),
    @DatabaseName varchar(100),
    @FileName0 varchar(1000),
    @FileName1 varchar(1000),
    @FileName2 varchar(1000),   
    @FileName3 varchar(1000),
    @FileName4 varchar(1000),
    @BackupName varchar(255),
    @wkYear varchar(4),
    @serverName varchar(50);

SET @databaseName = 'YourDatabaseName'; -- Set your database name here

-- Get the week number of the year
SET @wkYear = (SELECT DATEPART(ww, GETDATE()));
SET @dt = GETDATE();

--Extracting the server name
SET @serverName = SUBSTRING(@@servername, 1, CHARINDEX('\', @@servername) - 1);
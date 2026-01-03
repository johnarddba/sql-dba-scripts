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
        @serverName varchar(50),
        @BackupFolder varchar(512);

    SET @DatabaseName = 'YourDatabaseName';
    SET @BackupFolder = 'C:\Backups\Stripe5\';

    SET @wkYear = CAST(DATEPART(ww, GETDATE()) AS varchar(4));
    SET @dt = GETDATE();

    SET @serverName =
        CASE WHEN CHARINDEX('\', @@SERVERNAME) > 0
             THEN SUBSTRING(@@SERVERNAME, 1, CHARINDEX('\', @@SERVERNAME) - 1)
             ELSE @@SERVERNAME
        END;

    SET @dtt = CONVERT(varchar(8), @dt, 112) + REPLACE(CONVERT(varchar(8), @dt, 108), ':', '');

    SET @BackupName = @DatabaseName + '_' + @serverName + '_wk' + @wkYear + '_' + @dtt;

    SET @FileName0 = @BackupFolder + @BackupName + '_stripe0.bak';
    SET @FileName1 = @BackupFolder + @BackupName + '_stripe1.bak';
    SET @FileName2 = @BackupFolder + @BackupName + '_stripe2.bak';
    SET @FileName3 = @BackupFolder + @BackupName + '_stripe3.bak';
    SET @FileName4 = @BackupFolder + @BackupName + '_stripe4.bak';

    IF EXISTS (SELECT 1 FROM sys.databases WHERE name = @DatabaseName)
    BEGIN
        EXEC('ALTER DATABASE [' + @DatabaseName + '] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [' + @DatabaseName + '];');
    END

    EXEC master.dbo.xp_restore_database
        @database = @DatabaseName,
        @filename = @FileName0,
        @filename = @FileName1,
        @filename = @FileName2,
        @filename = @FileName3,
        @filename = @FileName4,
        @with = 'REPLACE',
        @with = 'STATS=10';

    EXEC('ALTER DATABASE [' + @DatabaseName + '] SET MULTI_USER;');
END
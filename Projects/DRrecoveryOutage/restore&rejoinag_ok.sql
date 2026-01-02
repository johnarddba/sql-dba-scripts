USE master;
GO

DECLARE @BackupFolder NVARCHAR(255) = N'\\tshd53fsxot0001.hedgeservtest.com\rnd_db_tlogs\DR_Sync\';
DECLARE @DB NVARCHAR(128);
DECLARE @DefaultAG NVARCHAR(128);
DECLARE @CurrentAG NVARCHAR(128);
DECLARE @TargetAG NVARCHAR(128);
DECLARE @F0 NVARCHAR(MAX);
DECLARE @F1 NVARCHAR(MAX);
DECLARE @F2 NVARCHAR(MAX);
DECLARE @F3 NVARCHAR(MAX);
DECLARE @F4 NVARCHAR(MAX);

DECLARE @SQL NVARCHAR(MAX);
DECLARE @IsPrimary BIT = 0;

-- Check for Availability Group
SELECT TOP 1 @DefaultAG = name FROM sys.availability_groups;

IF @DefaultAG IS NULL
BEGIN
    PRINT 'No Availability Group found. Script will only restore databases.';
END
ELSE
BEGIN
    --PRINT 'Default Availability Group (for new DBs): ' + @DefaultAG;
    -- Check initial Primary status for default AG
    SELECT @IsPrimary = CASE WHEN role = 1 THEN 1 ELSE 0 END
    FROM sys.dm_hadr_availability_replica_states rs
    JOIN sys.availability_groups ag ON rs.group_id = ag.group_id
    WHERE ag.name = @DefaultAG AND rs.is_local = 1;
END

-- 2. Get All User Databases
IF OBJECT_ID('tempdb..#UserDBs') IS NOT NULL DROP TABLE #UserDBs;
CREATE TABLE #UserDBs (DBName NVARCHAR(128));

INSERT INTO #UserDBs (DBName)
SELECT name 
FROM sys.databases 
WHERE database_id > 5 
  AND state_desc <> 'OFFLINE';

WHILE EXISTS(SELECT 1 FROM #UserDBs)
BEGIN
    SELECT TOP 1 @DB = DBName FROM #UserDBs;

    PRINT '--------------------------------------------------';
    PRINT 'Processing database: ' + @DB;

    BEGIN TRY
        SET @CurrentAG = NULL;
        SET @TargetAG = @DefaultAG; 

        -- A. Determine Current AG for this specific database
        SELECT @CurrentAG = ag.name
        FROM sys.availability_databases_cluster adc
        JOIN sys.availability_groups ag ON adc.group_id = ag.group_id
        WHERE adc.database_name = @DB;

        -- If DB is in an AG, remove it from THAT AG
        IF @CurrentAG IS NOT NULL
        BEGIN
            PRINT ' - Database is in Availability Group: ' + @CurrentAG;
            PRINT ' - Removing from Availability Group...';
            SET @SQL = 'ALTER AVAILABILITY GROUP [' + @CurrentAG + '] REMOVE DATABASE [' + @DB + '];';
            EXEC(@SQL);
			--PRINT @SQL;
            WAITFOR DELAY '00:00:05';
            
            SET @TargetAG = @CurrentAG;
        END

        -- Update Primary status check for the specific Target AG
        IF @TargetAG IS NOT NULL AND @TargetAG <> @DefaultAG
        BEGIN
             SELECT @IsPrimary = CASE WHEN role = 1 THEN 1 ELSE 0 END
             FROM sys.dm_hadr_availability_replica_states rs
             JOIN sys.availability_groups ag ON rs.group_id = ag.group_id
             WHERE ag.name = @TargetAG AND rs.is_local = 1;
        END

        -- B. Set Single User to kill connections
   --     IF EXISTS(SELECT 1 FROM sys.databases WHERE name = @DB)
   --     BEGIN
   --         PRINT ' - Setting SINGLE_USER...';
   --         SET @SQL = 'ALTER DATABASE [' + @DB + '] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;';
   --         EXEC(@SQL);
			----PRINT @SQL;
   --     END

        -- C. Restore from LiteSpeed Backup 
      
		SET @F0 = @BackupFolder + @DB + '_DR_FULL' + '_part0.LBK';
        SET @F1 = @BackupFolder + @DB + '_DR_FULL' + '_part1.LBK';
        SET @F2 = @BackupFolder + @DB + '_DR_FULL' + '_part2.LBK';
        SET @F3 = @BackupFolder + @DB + '_DR_FULL' + '_part3.LBK';
        SET @F4 = @BackupFolder + @DB + '_DR_FULL' + '_part4.LBK';
        

        PRINT ' - Restoring from DR backups...';
        EXEC master.dbo.xp_restore_database
            @database = @DB,
            @filename = @F0,
			@filename = @F1,
            @filename = @F2,
            @filename = @F3,
            @filename = @F4,
           
            @with = 'REPLACE',
            @with = 'STATS=10';

        -- D. Set Multi User
        PRINT ' - Setting MULTI_USER...';
        SET @SQL = 'ALTER DATABASE [' + @DB + '] SET MULTI_USER;';
        EXEC(@SQL);
		--PRINT @SQL;

        -- E. Set Recovery FULL
        IF (SELECT recovery_model FROM sys.databases WHERE name = @DB) <> 1
        BEGIN
            PRINT ' - Setting Recovery FULL...';
            SET @SQL = 'ALTER DATABASE [' + @DB + '] SET RECOVERY FULL;';
            EXEC(@SQL);
			--PRINT @SQL;
        END

        -- F. Add to AG and Resume
        IF @TargetAG IS NOT NULL
        BEGIN
            IF @IsPrimary = 1
            BEGIN
                PRINT ' - Adding to Availability Group [' + @TargetAG + ']...';
                SET @SQL = 'ALTER AVAILABILITY GROUP [' + @TargetAG + '] ADD DATABASE [' + @DB + '];';
                EXEC(@SQL);
				--PRINT @SQL;
                
                PRINT ' - Resuming Data Movement...';
                BEGIN TRY
                    SET @SQL = 'ALTER DATABASE [' + @DB + '] SET HADR RESUME;';
                    EXEC(@SQL);
					--PRINT @SQL;
                END TRY
                BEGIN CATCH
                    PRINT '   Warning: Resume failed: ' + ERROR_MESSAGE();
                END CATCH
            END
            ELSE
            BEGIN
                PRINT ' - Skipping AG Add: Server is not Primary for AG [' + @TargetAG + '].';
            END
        END
        
        PRINT ' - Done.';

    END TRY
    BEGIN CATCH
        PRINT 'Error processing ' + @DB + ': ' + ERROR_MESSAGE();
        -- Cleanup attempt
        BEGIN TRY
            SET @SQL = 'ALTER DATABASE [' + @DB + '] SET MULTI_USER;';
            EXEC(@SQL);
			--PRINT @SQL;
        END TRY
        BEGIN CATCH END CATCH
    END CATCH

    DELETE FROM #UserDBs WHERE DBName = @DB;
END

IF OBJECT_ID('tempdb..#UserDBs') IS NOT NULL DROP TABLE #UserDBs;
GO

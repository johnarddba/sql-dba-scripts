DROP TABLE IF EXISTS #TypeCapacity;
CREATE TABLE #TypeCapacity(
    SchemaName NVARCHAR(128),
    TableName NVARCHAR(128),
    ColumnName NVARCHAR(128),
    DataType NVARCHAR(30),
    ActualMaxValue BIGINT,
    TheoreticalMaxValue BIGINT,
    PercentFull DECIMAL(10, 2),
    OverEighty NVARCHAR(3),
    HasUniqueConstraint NVARCHAR(3)
);

DECLARE @SchemaName NVARCHAR(128);
DECLARE @TableName NVARCHAR(128);
DECLARE @ColumnName NVARCHAR(128);
DECLARE @DataType NVARCHAR(30);
DECLARE @TheoreticalMax BIGINT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE @ActualMax BIGINT;
DECLARE @ParmDefinition NVARCHAR(500);
DECLARE @PercentFull DECIMAL(10, 2);
DECLARE @HasUQ NVARCHAR(3);

DECLARE type_cursor CURSOR FOR
WITH TargetTable AS (
   SELECT TOP 10
    t.object_id,
    s.name AS schema_name,
    t.name AS table_name,
    SUM(ps.used_page_count) * 8 AS data_size_kb,
    SUM(ps.reserved_page_count) * 8 AS reserved_size_kb
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    JOIN sys.dm_db_partition_stats ps ON ps.object_id = t.object_id
    GROUP BY t.object_id, s.name, t.name
    ORDER BY data_size_kb DESC
)
SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    c.name AS ColumnName,
    CASE 
        WHEN ty.name = 'varbinary' THEN 
            ty.name + CASE WHEN c.max_length = -1 
                           THEN N'(max)' 
                           ELSE N'(' + CAST(c.max_length AS NVARCHAR(10)) + N')' 
                      END
        ELSE ty.name
    END AS DataType,
    CASE ty.name
        WHEN 'tinyint'   THEN 255
        WHEN 'smallint'  THEN 32767
        WHEN 'int'       THEN 2147483647
        WHEN 'varbinary' THEN CASE WHEN c.max_length = -1 
                                   THEN CAST(2147483647 AS BIGINT)
                                   ELSE CAST(c.max_length AS BIGINT)
                              END
    END AS TheoreticalMax,
    CASE WHEN EXISTS (
        SELECT 1
        FROM sys.key_constraints kc
        JOIN sys.index_columns ic
          ON ic.object_id = kc.parent_object_id
         AND ic.index_id  = kc.unique_index_id
         AND ic.column_id = c.column_id
        WHERE kc.parent_object_id = c.object_id
          AND kc.type = 'UQ'
    ) THEN N'YES' ELSE N'NO' END AS HasUniqueConstraint
FROM sys.columns c
INNER JOIN TargetTable tt ON c.object_id = tt.object_id
INNER JOIN sys.tables t    ON c.object_id = t.object_id
INNER JOIN sys.schemas s   ON t.schema_id = s.schema_id
INNER JOIN sys.types ty    ON c.user_type_id = ty.user_type_id
WHERE ty.name IN ('tinyint', 'smallint', 'int', 'varbinary');

OPEN type_cursor;

FETCH NEXT FROM type_cursor
INTO @SchemaName, @TableName, @ColumnName, @DataType, @TheoreticalMax, @HasUQ;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF LEFT(@DataType, 9) = 'varbinary'
    BEGIN
        SET @SQL = N'SELECT @MaxOut = MAX(DATALENGTH('
                 + QUOTENAME(@ColumnName) + N')) FROM '
                 + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName);
    END
    ELSE
    BEGIN
        SET @SQL = N'SELECT @MaxOut = MAX('
                 + QUOTENAME(@ColumnName) + N') FROM '
                 + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName);
    END

    SET @ParmDefinition = N'@MaxOut BIGINT OUTPUT';

    BEGIN TRY
        EXEC sp_executesql @SQL, @ParmDefinition, @MaxOut = @ActualMax OUTPUT;

        SET @ActualMax = ISNULL(@ActualMax, 0);

        SET @PercentFull = CASE
            WHEN @ActualMax > 0 AND @TheoreticalMax > 0 
                THEN (@ActualMax * 1.0 / @TheoreticalMax) * 100
            ELSE 0
        END;

        INSERT INTO #TypeCapacity
        (
            SchemaName, TableName, ColumnName, DataType,
            ActualMaxValue, TheoreticalMaxValue, PercentFull, OverEighty,
            HasUniqueConstraint
        )
        VALUES
        (
            @SchemaName,
            @TableName,
            @ColumnName,
            @DataType,
            @ActualMax,
            @TheoreticalMax,
            @PercentFull,
            CASE WHEN @PercentFull > 80.00 THEN 'YES' ELSE 'NO' END,
            @HasUQ
        );
    END TRY
    BEGIN CATCH
        PRINT 'Error processing ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + '.' + QUOTENAME(@ColumnName) 
              + ' : ' + ERROR_MESSAGE();
    END CATCH

    FETCH NEXT FROM type_cursor
    INTO @SchemaName, @TableName, @ColumnName, @DataType, @TheoreticalMax, @HasUQ;
END

CLOSE type_cursor;
DEALLOCATE type_cursor;

SELECT *
FROM #TypeCapacity
ORDER BY DataType, PercentFull DESC;

DROP TABLE #TypeCapacity;
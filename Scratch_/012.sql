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

-- Build and execute dynamic SQL for all columns at once
DECLARE @SQL NVARCHAR(MAX) = N'';

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
),
ColumnInfo AS (
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
    WHERE ty.name IN ('tinyint', 'smallint', 'int', 'varbinary')
)
SELECT @SQL = @SQL + 
    N'BEGIN TRY ' +
    N'INSERT INTO #TypeCapacity (SchemaName, TableName, ColumnName, DataType, ActualMaxValue, TheoreticalMaxValue, PercentFull, OverEighty, HasUniqueConstraint) ' +
    N'SELECT ' +
        QUOTENAME(SchemaName, '''') + N', ' +
        QUOTENAME(TableName, '''') + N', ' +
        QUOTENAME(ColumnName, '''') + N', ' +
        QUOTENAME(DataType, '''') + N', ' +
        CASE 
            WHEN LEFT(DataType, 9) = 'varbinary' 
                THEN N'ISNULL(MAX(DATALENGTH(' + QUOTENAME(ColumnName) + N')), 0)'
            ELSE N'ISNULL(MAX(' + QUOTENAME(ColumnName) + N'), 0)'
        END + N', ' +
        CAST(TheoreticalMax AS NVARCHAR(20)) + N', ' +
        N'CASE WHEN ISNULL(MAX(' + 
            CASE WHEN LEFT(DataType, 9) = 'varbinary' 
                THEN N'DATALENGTH(' + QUOTENAME(ColumnName) + N')'
                ELSE QUOTENAME(ColumnName)
            END + N'), 0) > 0 AND ' + CAST(TheoreticalMax AS NVARCHAR(20)) + N' > 0 ' +
            N'THEN (ISNULL(MAX(' + 
            CASE WHEN LEFT(DataType, 9) = 'varbinary' 
                THEN N'DATALENGTH(' + QUOTENAME(ColumnName) + N')'
                ELSE QUOTENAME(ColumnName)
            END + N'), 0) * 1.0 / ' + CAST(TheoreticalMax AS NVARCHAR(20)) + N') * 100 ' +
            N'ELSE 0 END, ' +
        N'CASE WHEN (ISNULL(MAX(' + 
            CASE WHEN LEFT(DataType, 9) = 'varbinary' 
                THEN N'DATALENGTH(' + QUOTENAME(ColumnName) + N')'
                ELSE QUOTENAME(ColumnName)
            END + N'), 0) * 1.0 / ' + CAST(TheoreticalMax AS NVARCHAR(20)) + N') * 100 > 80.00 THEN ''YES'' ELSE ''NO'' END, ' +
        QUOTENAME(HasUniqueConstraint, '''') + N' ' +
    N'FROM ' + QUOTENAME(SchemaName) + N'.' + QUOTENAME(TableName) + N'; ' +
    N'END TRY ' +
    N'BEGIN CATCH ' +
    N'PRINT ''Error processing '' + ' + QUOTENAME(SchemaName, '''') + N' + ''.'' + ' + QUOTENAME(TableName, '''') + N' + ''.'' + ' + QUOTENAME(ColumnName, '''') + 
    N' + '' : '' + ERROR_MESSAGE(); ' +
    N'END CATCH '
FROM ColumnInfo;

EXEC sp_executesql @SQL;

SELECT *
FROM #TypeCapacity
ORDER BY DataType, PercentFull DESC;

DROP TABLE #TypeCapacity;
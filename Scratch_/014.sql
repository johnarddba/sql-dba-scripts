DROP TABLE IF EXISTS #TypeCapacity;
CREATE TABLE #TypeCapacity(
    SchemaName NVARCHAR(128),
    TableName NVARCHAR(128),
    ColumnName NVARCHAR(128),
    DataType NVARCHAR(30),
    ActualMaxValue BIGINT,
    TheoreticalMaxValue BIGINT,
    RemainingCapacity BIGINT,
    TotalRows BIGINT,
    RemainingCapacityPerRow DECIMAL(18, 2),
    RemainingCapacityPercent DECIMAL(10, 2),
    ShouldIncrease NVARCHAR(3)
);

DECLARE @SQL NVARCHAR(MAX) = N'';

WITH TargetTable AS (
   SELECT TOP 10
    t.object_id,
    s.name AS schema_name,
    t.name AS table_name,
    SUM(ps.used_page_count) * 8 AS data_size_kb
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
        ty.name AS DataType,
        CASE ty.name
            WHEN 'tinyint'   THEN 255
            WHEN 'smallint'  THEN 32767
            WHEN 'int'       THEN 2147483647
        END AS TheoreticalMax
    FROM sys.columns c
    INNER JOIN TargetTable tt ON c.object_id = tt.object_id
    INNER JOIN sys.tables t    ON c.object_id = t.object_id
    INNER JOIN sys.schemas s   ON t.schema_id = s.schema_id
    INNER JOIN sys.types ty    ON c.user_type_id = ty.user_type_id
    WHERE ty.name IN ('tinyint', 'smallint', 'int')
)
SELECT @SQL = @SQL + 
    N'BEGIN TRY ' +
    N'INSERT INTO #TypeCapacity (SchemaName, TableName, ColumnName, DataType, ActualMaxValue, TheoreticalMaxValue, RemainingCapacity, TotalRows, RemainingCapacityPerRow, RemainingCapacityPercent, ShouldIncrease) ' +
    N'SELECT ' +
        QUOTENAME(SchemaName, '''') + N', ' +
        QUOTENAME(TableName, '''') + N', ' +
        QUOTENAME(ColumnName, '''') + N', ' +
        QUOTENAME(DataType, '''') + N', ' +
        N'ISNULL(MAX(' + QUOTENAME(ColumnName) + N'), 0), ' +
        CAST(TheoreticalMax AS NVARCHAR(20)) + N', ' +
        CAST(TheoreticalMax AS NVARCHAR(20)) + N' - ISNULL(MAX(' + QUOTENAME(ColumnName) + N'), 0), ' +
        N'(SELECT COUNT(*) FROM ' + QUOTENAME(SchemaName) + N'.' + QUOTENAME(TableName) + N'), ' +
        N'CASE WHEN (SELECT COUNT(*) FROM ' + QUOTENAME(SchemaName) + N'.' + QUOTENAME(TableName) + N') > 0 ' +
            N'THEN CAST((' + CAST(TheoreticalMax AS NVARCHAR(20)) + N' - ISNULL(MAX(' + QUOTENAME(ColumnName) + N'), 0)) AS DECIMAL(18,2)) / (SELECT COUNT(*) FROM ' + QUOTENAME(SchemaName) + N'.' + QUOTENAME(TableName) + N') ' +
            N'ELSE 0 END, ' +
        N'CASE WHEN ' + CAST(TheoreticalMax AS NVARCHAR(20)) + N' > 0 ' +
            N'THEN ((CAST(' + CAST(TheoreticalMax AS NVARCHAR(20)) + N' AS DECIMAL(18,2)) - ISNULL(MAX(' + QUOTENAME(ColumnName) + N'), 0)) / ' + CAST(TheoreticalMax AS NVARCHAR(20)) + N') * 100 ' +
            N'ELSE 0 END, ' +
        N'CASE WHEN ((CAST(' + CAST(TheoreticalMax AS NVARCHAR(20)) + N' AS DECIMAL(18,2)) - ISNULL(MAX(' + QUOTENAME(ColumnName) + N'), 0)) / ' + CAST(TheoreticalMax AS NVARCHAR(20)) + N') * 100 < 20.00 THEN ''YES'' ELSE ''NO'' END ' +
    N'FROM ' + QUOTENAME(SchemaName) + N'.' + QUOTENAME(TableName) + N'; ' +
    N'END TRY ' +
    N'BEGIN CATCH ' +
    N'PRINT ''Error processing '' + ' + QUOTENAME(SchemaName, '''') + N' + ''.'' + ' + QUOTENAME(TableName, '''') + N' + ''.'' + ' + QUOTENAME(ColumnName, '''') + 
    N' + '' : '' + ERROR_MESSAGE(); ' +
    N'END CATCH '
FROM ColumnInfo;

EXEC sp_executesql @SQL;

SELECT 
    SchemaName,
    TableName,
    ColumnName,
    DataType,
    ActualMaxValue,
    TheoreticalMaxValue,
    RemainingCapacity,
    TotalRows,
    RemainingCapacityPerRow,
    RemainingCapacityPercent,
    ShouldIncrease
FROM #TypeCapacity
WHERE ShouldIncrease = 'YES'
ORDER BY RemainingCapacityPercent ASC, DataType, TableName, ColumnName;

DROP TABLE #TypeCapacity;

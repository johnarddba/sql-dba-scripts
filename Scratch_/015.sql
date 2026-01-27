/* For SQL Server: scan all tinyint, smallint, and int columns
   Reports row count, nulls, min/max, max possible, and % of range used */
SET NOCOUNT ON;

DECLARE @sql nvarchar(max) = N'';

SELECT @sql = @sql + N'
SELECT
    SchemaName  = ' + QUOTENAME(s.name,'''') + N',
    TableName   = ' + QUOTENAME(t.name,'''') + N',
    ColumnName  = ' + QUOTENAME(c.name,'''') + N',
    DataType    = ' + QUOTENAME(TYPE_NAME(c.system_type_id),'''') + N',
    RowCount    = COUNT_BIG(*),
    NullCount   = SUM(CASE WHEN ' + QUOTENAME(c.name) + N' IS NULL THEN 1 ELSE 0 END),
    CurrentMin  = MIN(CAST(' + QUOTENAME(c.name) + N' AS bigint)),
    CurrentMax  = MAX(CAST(' + QUOTENAME(c.name) + N' AS bigint)),
    MaxPossible = ' + CAST(
                      CASE c.system_type_id
                           WHEN 48 THEN 255          -- tinyint
                           WHEN 52 THEN 32767        -- smallint
                           WHEN 56 THEN 2147483647   -- int
                      END AS nvarchar(20)) + N',
    PctUsed     = CAST(
                     MAX(ABS(CAST(' + QUOTENAME(c.name) + N' AS float))) * 100.0 /
                     ' + CAST(
                           CASE c.system_type_id
                                WHEN 48 THEN 255
                                WHEN 52 THEN 32767
                                WHEN 56 THEN 2147483647
                           END AS nvarchar(20)) + N'
                   AS decimal(9,2))
FROM ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N' WITH (NOLOCK)
UNION ALL'
FROM sys.tables  t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
WHERE t.is_ms_shipped = 0
  AND c.is_computed   = 0
  AND c.system_type_id IN (48, 52, 56);  -- tinyint, smallint, int

IF @sql = N''
BEGIN
    SELECT Message = 'No columns found with system_type_id in (48,52,56).';
    RETURN;
END;

-- Remove trailing UNION ALL, and add ordering
SET @sql = LEFT(@sql, LEN(@sql) - LEN('UNION ALL')) + N'
ORDER BY SchemaName, TableName, ColumnName;';

EXEC sys.sp_executesql @sql;
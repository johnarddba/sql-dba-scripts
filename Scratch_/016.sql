SET NOCOUNT ON;

DECLARE @sql nvarchar(max) = N'';

SELECT @sql = @sql +
N'
SELECT
    SchemaName   = ' + QUOTENAME(s.name,'''') + N',
    TableName    = ' + QUOTENAME(t.name,'''') + N',
    ColumnName   = ' + QUOTENAME(c.name,'''') + N',
    DataType     = ' + QUOTENAME(CASE 
                        WHEN c.system_type_id = 1 THEN 'tinyint'
                        WHEN c.system_type_id = 52 THEN 'smallint'
                        WHEN c.system_type_id = 56 THEN 'int'
                      END, '''') + N',
    RowCount     = COUNT_BIG(*),
    NullCount    = SUM(CASE WHEN ' + QUOTENAME(c.name) + N' IS NULL THEN 1 ELSE 0 END),
    CurrentMax   = MAX(CAST(' + QUOTENAME(c.name) + N' AS bigint)),
    MaxPossible  = ' + CAST(CASE 
                        WHEN c.system_type_id = 1 THEN 255
                        WHEN c.system_type_id = 52 THEN 32767
                        WHEN c.system_type_id = 56 THEN 2147483647
                      END AS nvarchar(20)) + N',
    PctUsed      = CAST(
                    MAX(CAST(' + QUOTENAME(c.name) + N' AS float)) * 100.0 / ' + CAST(CASE 
                        WHEN c.system_type_id = 1 THEN 255.0
                        WHEN c.system_type_id = 52 THEN 32767.0
                        WHEN c.system_type_id = 56 THEN 2147483647.0
                      END AS nvarchar(20)) + N'
                   AS decimal(9,2))
FROM ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N' WITH (NOLOCK)
UNION ALL'
FROM sys.tables  t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
WHERE t.is_ms_shipped = 0
  AND c.is_computed   = 0
  AND c.system_type_id IN (1, 52, 56);  -- tinyint, smallint, int

IF @sql = N''
BEGIN
    SELECT Message = 'No integer columns found (tinyint, smallint, or int).';
    RETURN;
END;

-- Remove trailing UNION ALL, and add ordering
SET @sql = LEFT(@sql, LEN(@sql) - LEN('UNION ALL')) + N'
ORDER BY SchemaName, TableName, ColumnName;';

EXEC sys.sp_executesql @sql;
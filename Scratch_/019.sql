DECLARE @sql NVARCHAR(MAX) = N'';

-- Build individual EXEC statements for each column
SELECT @sql = @sql + N'
EXEC sp_executesql N''
SELECT 
    ''''' + TABLE_NAME + ''''' AS TableName, 
    ''''' + COLUMN_NAME + ''''' AS ColumnName, 
    MAX([' + COLUMN_NAME + ']) AS CurrentMaxValue,
    CASE 
        WHEN MAX([' + COLUMN_NAME + ']) <= 255 AND MIN([' + COLUMN_NAME + ']) >= 0 THEN ''''TINYINT''''
        WHEN MAX([' + COLUMN_NAME + ']) <= 32767 AND MIN([' + COLUMN_NAME + ']) >= -32768 THEN ''''SMALLINT''''
        ELSE ''''Keep as INT''''
    END AS RecommendedType
FROM [' + TABLE_SCHEMA + '].[' + TABLE_NAME + '];
'';'
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE DATA_TYPE = 'int' 
  AND TABLE_SCHEMA != 'sys';

-- Execute all the built statements
EXEC sp_executesql @sql;
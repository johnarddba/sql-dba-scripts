DECLARE @Cols TABLE (
    schema_name sysname,
    table_name sysname,
    column_name sysname,
    type_name sysname,
    max_length int,
    precision tinyint,
    scale tinyint
);

INSERT INTO @Cols
SELECT 
    s.name,
    t.name,
    c.name,
    ty.name,
    c.max_length,
    c.precision,
    c.scale
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.is_ms_shipped = 0;

DECLARE @Results TABLE (
    schema_name sysname,
    table_name sysname,
    column_name sysname,
    type_name sysname,
    declared_capacity_numeric decimal(38,18) NULL,
    declared_capacity_length int NULL,
    current_max_numeric decimal(38,18) NULL,
    current_max_length int NULL,
    is_max_type bit NULL
);

DECLARE @sql_num nvarchar(max) = N'';
DECLARE @sql_final nvarchar(max) = N'';

-- Build numeric queries for integer types only (tinyint, smallint, int)
SELECT @sql_num = (
    SELECT 
        'SELECT ' +
        '''' + schema_name + ''' AS schema_name, ' +
        '''' + table_name + ''' AS table_name, ' +
        '''' + column_name + ''' AS column_name, ' +
        '''' + type_name + ''' AS type_name, ' +
        CASE 
            WHEN type_name = 'tinyint'      THEN 'CAST(255 AS decimal(38,18))'
            WHEN type_name = 'smallint'     THEN 'CAST(32767 AS decimal(38,18))'
            WHEN type_name = 'int'          THEN 'CAST(2147483647 AS decimal(38,18))'
            ELSE 'NULL'
        END + ' AS declared_capacity_numeric, ' +
        'NULL AS declared_capacity_length, ' +
        'MAX(CAST(' + QUOTENAME(column_name) + 
            CASE 
                WHEN type_name IN ('tinyint','smallint','int') THEN ' AS bigint))'
                ELSE ' AS decimal(38,18)))'
            END + ' AS current_max_numeric, ' +
        'NULL AS current_max_length, ' +
        '0 AS is_max_type ' +
        'FROM ' + QUOTENAME(schema_name) + '.' + QUOTENAME(table_name) + 
        ' UNION ALL '
    FROM @Cols
    WHERE type_name IN ('tinyint','smallint','int')
    FOR XML PATH(''), TYPE
).value('.', 'nvarchar(max)');

-- Remove trailing UNION ALL if we have content
IF LEN(@sql_num) > 0
    SET @sql_final = LEFT(@sql_num, LEN(@sql_num) - LEN(' UNION ALL '));

DECLARE @sql nvarchar(max) = @sql_final;

IF @sql IS NOT NULL AND @sql != N''
BEGIN
    INSERT INTO @Results(schema_name, table_name, column_name, type_name,
                         declared_capacity_numeric, declared_capacity_length,
                         current_max_numeric, current_max_length, is_max_type)
    EXEC sp_executesql @sql;
END

SELECT 
    schema_name,
    table_name,
    column_name,
    type_name,
    declared_capacity_numeric,
    declared_capacity_length,
    current_max_numeric,
    current_max_length,
    CASE WHEN declared_capacity_numeric IS NOT NULL AND current_max_numeric IS NOT NULL 
         THEN declared_capacity_numeric - current_max_numeric 
         ELSE NULL END AS remaining_to_limit_numeric,
    CASE WHEN declared_capacity_length IS NOT NULL AND current_max_length IS NOT NULL 
         THEN declared_capacity_length - current_max_length 
         ELSE NULL END AS remaining_to_limit_length,
    is_max_type
FROM @Results
ORDER BY schema_name, table_name, column_name;


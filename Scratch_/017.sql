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

DECLARE @sql_num nvarchar(max);
DECLARE @sql_len nvarchar(max);

SELECT @sql_num = STRING_AGG(
    'SELECT ' +
    '''' + schema_name + ''' AS schema_name, ' +
    '''' + table_name + ''' AS table_name, ' +
    '''' + column_name + ''' AS column_name, ' +
    '''' + type_name + ''' AS type_name, ' +
    CASE 
        WHEN type_name = 'tinyint'      THEN 'CAST(255 AS decimal(38,18))'
        WHEN type_name = 'smallint'     THEN 'CAST(32767 AS decimal(38,18))'
        WHEN type_name = 'int'          THEN 'CAST(2147483647 AS decimal(38,18))'
        WHEN type_name = 'bigint'       THEN 'CAST(9223372036854775807 AS decimal(38,18))'
        WHEN type_name = 'bit'          THEN 'CAST(1 AS decimal(38,18))'
        WHEN type_name = 'money'        THEN 'CAST(922337203685477.5807 AS decimal(38,18))'
        WHEN type_name = 'smallmoney'   THEN 'CAST(214748.3647 AS decimal(38,18))'
        WHEN type_name IN ('decimal','numeric') 
            THEN 'CAST(POWER(10.0, ' + CAST(precision as varchar(10)) + ' - ' + CAST(scale as varchar(10)) + ') - POWER(10.0, -' + CAST(scale as varchar(10)) + ') AS decimal(38,18))'
        ELSE 'NULL'
    END + ' AS declared_capacity_numeric, ' +
    'NULL AS declared_capacity_length, ' +
    'MAX(CAST(' + QUOTENAME(column_name) + 
        CASE 
            WHEN type_name IN ('tinyint','smallint','int') THEN ' AS bigint))'
            WHEN type_name = 'bigint' THEN ' AS decimal(38,0)))'
            WHEN type_name = 'bit' THEN ' AS int))'
            WHEN type_name IN ('money','smallmoney') THEN ' AS decimal(19,4)))'
            WHEN type_name IN ('decimal','numeric') THEN ' AS decimal(38,18)))'
            ELSE ' AS decimal(38,18)))'
        END + ' AS current_max_numeric, ' +
    'NULL AS current_max_length, ' +
    '0 AS is_max_type ' +
    'FROM ' + QUOTENAME(schema_name) + '.' + QUOTENAME(table_name)
, ' UNION ALL ')
FROM @Cols
WHERE type_name IN ('tinyint','smallint','int','bigint','bit','money','smallmoney','decimal','numeric');

SELECT @sql_len = STRING_AGG(
    'SELECT ' +
    '''' + schema_name + ''' AS schema_name, ' +
    '''' + table_name + ''' AS table_name, ' +
    '''' + column_name + ''' AS column_name, ' +
    '''' + type_name + ''' AS type_name, ' +
    'NULL AS declared_capacity_numeric, ' +
    CASE 
        WHEN max_length = -1 THEN 'NULL'
        WHEN type_name IN ('nvarchar','nchar') THEN CAST((max_length/2) as varchar(10))
        ELSE CAST(max_length as varchar(10))
    END + ' AS declared_capacity_length, ' +
    'NULL AS current_max_numeric, ' +
    'MAX(' + 
        CASE 
            WHEN type_name IN ('varbinary','binary') THEN 'DATALENGTH(' + QUOTENAME(column_name) + ')'
            ELSE 'LEN(' + QUOTENAME(column_name) + ')'
        END + 
    ') AS current_max_length, ' +
    CASE WHEN max_length = -1 THEN '1' ELSE '0' END + ' AS is_max_type ' +
    'FROM ' + QUOTENAME(schema_name) + '.' + QUOTENAME(table_name)
, ' UNION ALL ')
FROM @Cols
WHERE type_name IN ('varchar','char','nvarchar','nchar','varbinary','binary');

DECLARE @sql nvarchar(max) = NULL;
SET @sql = 
    CASE 
        WHEN @sql_num IS NOT NULL AND @sql_len IS NOT NULL THEN @sql_num + ' UNION ALL ' + @sql_len
        ELSE COALESCE(@sql_num, @sql_len)
    END;

IF @sql IS NOT NULL
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

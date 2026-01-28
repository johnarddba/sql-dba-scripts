/*
 * Monitor int, tinyint, smallint columns: actual sizes vs type range.
 * No cursors. Top 10 tables only.
 *
 * Output: schemaname, tablename, columnname, datatype, actualmaxvalue, maxvalue,
 *         remainingcapacity, totalrows, remainingcapacityperrow,
 *         remainingcapacitypercentage, isidentity, incrementvalue, shouldincrease
 */

SET NOCOUNT ON;

-- Type ranges (max positive; used for capacity)
DECLARE @TinyintMax BIGINT = 255;
DECLARE @SmallintMax BIGINT = 32767;
DECLARE @IntMax BIGINT = 2147483647;

-- Build dynamic SQL: one SELECT per column (MAX, COUNT), UNION ALL
DECLARE @sql NVARCHAR(MAX) = '';

;WITH TypeRanges AS (
    SELECT 'tinyint' AS datatype, @TinyintMax AS maxval
    UNION ALL SELECT 'smallint', @SmallintMax
    UNION ALL SELECT 'int', @IntMax
),
TopTables AS (
    SELECT DISTINCT TOP 10
        OBJECT_SCHEMA_NAME(c.object_id) AS schemaname,
        OBJECT_NAME(c.object_id) AS tablename
    FROM sys.columns c
    INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
    INNER JOIN sys.tables t ON t.object_id = c.object_id
    WHERE ty.name IN ('int', 'tinyint', 'smallint')
    ORDER BY OBJECT_SCHEMA_NAME(c.object_id), OBJECT_NAME(c.object_id)
),
Cols AS (
    SELECT
        tt.schemaname,
        tt.tablename,
        c.name AS columnname,
        ty.name AS datatype,
        tr.maxval,
        CAST(ISNULL(ic.is_identity, 0) AS TINYINT) AS isidentity,
        ISNULL(CAST(ic.increment_value AS BIGINT), 0) AS incrementvalue
    FROM TopTables tt
    INNER JOIN sys.columns c
        ON OBJECT_SCHEMA_NAME(c.object_id) = tt.schemaname
       AND OBJECT_NAME(c.object_id) = tt.tablename
    INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
    INNER JOIN TypeRanges tr ON tr.datatype = ty.name
    LEFT JOIN sys.identity_columns ic
        ON ic.object_id = c.object_id AND ic.column_id = c.column_id
    WHERE ty.name IN ('int', 'tinyint', 'smallint')
)
SELECT @sql = @sql +
    'SELECT N''' + REPLACE(schemaname, '''', '''''') + ''' AS schemaname, ' +
    'N''' + REPLACE(tablename, '''', '''''') + ''' AS tablename, ' +
    'N''' + REPLACE(columnname, '''', '''''') + ''' AS columnname, ' +
    'N''' + datatype + ''' AS datatype, ' +
    'MAX(TRY_CAST(' + QUOTENAME(columnname) + ' AS BIGINT)) AS actualmaxvalue, ' +
    'CAST(' + CAST(maxval AS VARCHAR(20)) + ' AS BIGINT) AS maxvalue, ' +
    'COUNT(*) AS totalrows, ' +
    CAST(isidentity AS VARCHAR(1)) + ' AS isidentity, ' +
    CAST(incrementvalue AS VARCHAR(20)) + ' AS incrementvalue ' +
    'FROM ' + QUOTENAME(schemaname) + '.' + QUOTENAME(tablename) + ' UNION ALL '
FROM Cols;

IF LEN(@sql) = 0
BEGIN
    RAISERROR('No int/tinyint/smallint columns in top 10 tables.', 0, 1);
    RETURN;
END;

SET @sql = LEFT(@sql, LEN(@sql) - 10);

-- Create temp table and insert raw results (no cursor)
IF OBJECT_ID('tempdb..#Raw') IS NOT NULL DROP TABLE #Raw;

CREATE TABLE #Raw (
    schemaname NVARCHAR(128),
    tablename NVARCHAR(128),
    columnname NVARCHAR(128),
    datatype NVARCHAR(128),
    actualmaxvalue BIGINT,
    maxvalue BIGINT,
    totalrows BIGINT,
    isidentity TINYINT,
    incrementvalue BIGINT
);

INSERT INTO #Raw (schemaname, tablename, columnname, datatype, actualmaxvalue, maxvalue, totalrows, isidentity, incrementvalue)
EXEC sp_executesql @sql;

-- Final result with derived columns
SELECT
    r.schemaname,
    r.tablename,
    r.columnname,
    r.datatype,
    r.actualmaxvalue,
    r.maxvalue,
    r.maxvalue - ISNULL(r.actualmaxvalue, 0) AS remainingcapacity,
    r.totalrows,
    CASE
        WHEN r.totalrows > 0
        THEN (r.maxvalue - ISNULL(r.actualmaxvalue, 0)) * 1.0 / r.totalrows
        ELSE NULL
    END AS remainingcapacityperrow,
    CASE
        WHEN r.maxvalue > 0
        THEN 100.0 * (r.maxvalue - ISNULL(r.actualmaxvalue, 0)) / r.maxvalue
        ELSE NULL
    END AS remainingcapacitypercentage,
    r.isidentity AS isidentity,
    r.incrementvalue AS incrementvalue,
    CASE
        WHEN r.totalrows = 0 THEN 0
        WHEN 100.0 * (r.maxvalue - ISNULL(r.actualmaxvalue, 0)) / NULLIF(r.maxvalue, 0) < 20 THEN 1
        ELSE 0
    END AS shouldincrease
FROM #Raw r
ORDER BY r.schemaname, r.tablename, r.columnname;

DROP TABLE #Raw;

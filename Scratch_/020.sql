SELECT
	'tablename' AS TableName,
	'columnname' AS ColumnName,
	MAX([columnname]) AS CurrentMaxValue,
	CASE
		WHEN MAX([columnname]) <= 255 AND MIN([columnname]) >= 0 THEN 'TINYINT'
		WHEN MAX([columnname]) <= 32767 AND MIN([columnname]) >= -32768 THEN 'SMALLINT'
		ELSE 'KEEP as INT'
	END AS RecommendedType
FROM [schemaname].[tablename];DECLARE @sql nvarchar(max);

SELECT @sql =
  STRING_AGG(CONVERT(nvarchar(max),
    N'SELECT
        ' + QUOTENAME(s.name,'''') + N' AS SchemaName,
        ' + QUOTENAME(t.name,'''') + N' AS TableName,
        ' + QUOTENAME(c.name,'''') + N' AS ColumnName,
        MAX(CONVERT(bigint,' + QUOTENAME(c.name) + N')) AS CurrentMaxValue,
        MIN(CONVERT(bigint,' + QUOTENAME(c.name) + N')) AS CurrentMinValue
      FROM ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N' WITH (NOLOCK)'
  ), N' UNION ALL ')
FROM sys.tables  t
JOIN sys.schemas s  ON s.schema_id = t.schema_id
JOIN sys.columns c  ON c.object_id = t.object_id
JOIN sys.types   ty ON ty.user_type_id = c.user_type_id
WHERE t.is_ms_shipped = 0
  AND ty.name = N'int';

IF @sql IS NULL
BEGIN
  SELECT TOP (0)
    CAST(NULL AS sysname) AS SchemaName,
    CAST(NULL AS sysname) AS TableName,
    CAST(NULL AS sysname) AS LargestIntColumn,
    CAST(NULL AS bigint)  AS CurrentMaxValue,
    CAST(NULL AS bigint)  AS CurrentMinValue,
    CAST(NULL AS varchar(10)) AS RecommendedType;
  RETURN;
END;

SET @sql = N'
;WITH colStats AS (
' + @sql + N'
),
scored AS (
  SELECT
    *,
    CASE
      WHEN CurrentMinValue >= 0 AND CurrentMaxValue <= 255 THEN ''TINYINT''
      WHEN CurrentMinValue >= -32768 AND CurrentMaxValue <= 32767 THEN ''SMALLINT''
      ELSE ''INT''
    END AS RecommendedType,

    CAST(2147483647 - CurrentMaxValue AS bigint) AS IntHeadroomToMax,
    CAST(  32767    - CurrentMaxValue AS bigint) AS SmallintHeadroomToMax,
    CAST(    255    - CurrentMaxValue AS bigint) AS TinyintHeadroomToMax,

    CAST(CurrentMaxValue * 100.0 / 2147483647 AS decimal(9,4)) AS IntPctUsedOfMax,
    CAST(CurrentMaxValue * 100.0 /   32767    AS decimal(9,4)) AS SmallintPctUsedOfMax,
    CAST(CurrentMaxValue * 100.0 /     255    AS decimal(9,4)) AS TinyintPctUsedOfMax,

    CAST((2147483647 - CurrentMaxValue) * 100.0 / 2147483647 AS decimal(9,4)) AS IntPctRemainingToMax,
    CAST((  32767    - CurrentMaxValue) * 100.0 /   32767    AS decimal(9,4)) AS SmallintPctRemainingToMax,
    CAST((    255    - CurrentMaxValue) * 100.0 /     255    AS decimal(9,4)) AS TinyintPctRemainingToMax
  FROM colStats
),
perTable AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY SchemaName, TableName
      ORDER BY CurrentMaxValue DESC
    ) AS rn
  FROM scored
  WHERE CurrentMaxValue IS NOT NULL
)
SELECT TOP (10)
  SchemaName,
  TableName,
  ColumnName AS LargestIntColumn,
  CurrentMaxValue,
  CurrentMinValue,
  RecommendedType,

  IntHeadroomToMax,        IntPctUsedOfMax,        IntPctRemainingToMax,
  SmallintHeadroomToMax,   SmallintPctUsedOfMax,   SmallintPctRemainingToMax,
  TinyintHeadroomToMax,    TinyintPctUsedOfMax,    TinyintPctRemainingToMax
FROM perTable
WHERE rn = 1
ORDER BY CurrentMaxValue DESC;
';

EXEC sys.sp_executesql @sql;
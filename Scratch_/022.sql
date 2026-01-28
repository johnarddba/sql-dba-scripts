WITH rowcounts AS (
  SELECT p.object_id, SUM(p.row_count) AS row_count
  FROM sys.dm_db_partition_stats p
  WHERE p.index_id IN (0,1)
  GROUP BY p.object_id
),
ident AS (
  SELECT
    t.object_id,
    s.name AS SchemaName,
    t.name AS TableName,
    c.name AS ColumnName,
    CAST(IDENT_CURRENT(QUOTENAME(s.name) + '.' + QUOTENAME(t.name)) AS bigint) AS CurrentIdentityValue,
    CAST(2147483647 AS bigint) AS IntMaxValue
  FROM sys.tables t
  JOIN sys.schemas s ON s.schema_id = t.schema_id
  JOIN sys.columns c ON c.object_id = t.object_id
  WHERE t.is_ms_shipped = 0
    AND c.is_identity = 1
    AND TYPE_NAME(c.user_type_id) = N'int'
),
scored AS (
  SELECT
    i.SchemaName,
    i.TableName,
    i.ColumnName,
    rc.row_count AS TotalRows,
    i.CurrentIdentityValue,
    (i.IntMaxValue - i.CurrentIdentityValue) AS RemainingValues,
    CAST(
      CASE WHEN rc.row_count IS NULL OR rc.row_count = 0
           THEN NULL
           ELSE ( (i.IntMaxValue - i.CurrentIdentityValue) * 100.0 ) / rc.row_count
      END
      AS decimal(38,6)
    ) AS RemainingPctVsRows
  FROM ident i
  LEFT JOIN rowcounts rc ON rc.object_id = i.object_id
),
perTableWorst AS (
  SELECT *,
    ROW_NUMBER() OVER (
      PARTITION BY SchemaName, TableName
      ORDER BY RemainingPctVsRows ASC, RemainingValues ASC
    ) AS rn
  FROM scored
)
SELECT TOP (10)
  SchemaName,
  TableName,
  ColumnName AS IdentityIntColumn,
  TotalRows,
  CurrentIdentityValue,
  RemainingValues,
  RemainingPctVsRows,
  CASE
    WHEN RemainingPctVsRows IS NOT NULL AND RemainingPctVsRows < 20
      THEN 'INCREASE (consider BIGINT)'
    ELSE 'OK'
  END AS Recommendation
FROM perTableWorst
WHERE rn = 1
ORDER BY RemainingPctVsRows ASC, RemainingValues ASC;
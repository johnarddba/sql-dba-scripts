SELECT TOP (20)
    t.name AS TableName,
    s.name AS SchemaName,
    p.rows AS RowCounts,
    CAST(SUM(a.total_pages) * 8.0 / 1024 AS DECIMAL(10,2)) AS ReservedMB,
    CAST(SUM(a.used_pages) * 8.0 / 1024 AS DECIMAL(10,2)) AS UsedMB,
    CAST((SUM(a.total_pages) - SUM(a.used_pages)) * 8.0 / 1024 AS DECIMAL(10,2)) AS UnusedMB
FROM sys.tables t
JOIN sys.indexes i
    ON t.object_id = i.object_id
JOIN sys.partitions p
    ON i.object_id = p.object_id
   AND i.index_id = p.index_id
JOIN sys.allocation_units a
    ON p.partition_id = a.container_id
JOIN sys.schemas s
    ON t.schema_id = s.schema_id
GROUP BY
    t.name,
    s.name,
    p.rows
ORDER BY ReservedMB DESC;
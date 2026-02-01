SELECT name, 
       CAST(size * 8.0 / 1024 AS DECIMAL(12, 2)) AS Size_MB,
       CAST(FILEPROPERTY(name, 'SpaceUsed') * 8.0 / 1024 AS DECIMAL(12, 2)) AS Used_MB,
       CAST((size - FILEPROPERTY(name, 'SpaceUsed')) * 8.0 / 1024 AS DECIMAL(12, 2)) AS Free_MB
FROM sys.database_files;



SELECT TOP 10 
    t.name AS TableName, 
    p.rows AS RowCounts,
    (SUM(a.total_pages) * 8) / 1024 AS TotalSpaceMB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
GROUP BY t.name, p.rows
ORDER BY TotalSpaceMB DESC;


SELECT name, log_reuse_wait_desc 
FROM sys.databases 
WHERE name = 'YourDatabaseName';
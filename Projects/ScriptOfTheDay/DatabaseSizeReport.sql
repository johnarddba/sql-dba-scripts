SELECT
    DB_NAME(database_id) AS DatabaseName,
    CAST(SUM(size) * 8.0 / 1024 AS DECIMAL(10,2)) AS TotalSizeMB,
    CAST(SUM(CASE WHEN type_desc = 'ROWS' THEN size END) * 8.0 / 1024 AS DECIMAL(10,2)) AS DataSizeMB,
    CAST(SUM(CASE WHEN type_desc = 'LOG' THEN size END) * 8.0 / 1024 AS DECIMAL(10,2)) AS LogSizeMB
FROM sys.master_files
GROUP BY database_id
ORDER BY TotalSizeMB DESC;
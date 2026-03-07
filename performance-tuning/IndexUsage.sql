--select DB_ID()


SELECT
DB_NAME(database_id) AS [Database Name],
OBJECT_NAME(s.object_id) AS [Table Name],
i.name AS [Index Name],
s.*
FROM sys.dm_db_index_usage_stats AS s
JOIN sys.indexes i
ON i.object_id = s.object_id AND i.index_id = s.index_id
WHERE database_id = DB_ID()
SELECT * FROM sys.dm_db_missing_index_details

SELECT 
mig.*, statement as table_name, column_id, column_name, column_usage
FROM sys.dm_db_missing_index_details mid
CROSS APPLY sys.dm_db_missing_index_columns(mid.index_handle)
INNER JOIN sys.dm_db_missing_index_groups AS mig 
ON mid.index_handle = mig.index_handle
WHERE database_id = DB_ID()
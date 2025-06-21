--T-SQL CHECK DRIVE FREE SPACE

SELECT DISTINCT 
  vs.volume_mount_point
, vs.file_system_type
, vs.logical_volume_name
, vs.total_bytes/1073741824.0 [Total Size (GB)]
, vs.available_bytes/1073741824.0 [Available Size (GB)] 
, CAST(vs.available_bytes * 100. / vs.total_bytes AS DECIMAL(5,2)) AS [Space Free %] 
FROM 
  sys.master_files AS f WITH (NOLOCK)
    CROSS APPLY 
  sys.dm_os_volume_stats(f.database_id, f.[file_id]) AS vs;


-- This query retrieves the free space on each drive where SQL Server databases are stored.

SELECT 
    vs.volume_mount_point AS Drive,
    CAST(vs.total_bytes / 1073741824.0 AS DECIMAL(10,2)) AS TotalSize_GB,
    CAST((vs.total_bytes - vs.available_bytes) / 1073741824.0 AS DECIMAL(10,2)) AS UsedSize_GB,
    CAST(vs.available_bytes / 1073741824.0 AS DECIMAL(10,2)) AS FreeSize_GB,
    CAST(CAST(100.0 * (vs.total_bytes - vs.available_bytes) / vs.total_bytes AS DECIMAL(5,2)) AS VARCHAR(10)) + ' %' AS PercentUsed,
    CAST(CAST(100.0 * vs.available_bytes / vs.total_bytes AS DECIMAL(5,2)) AS VARCHAR(10)) + ' %' AS PercentFree
FROM 
    sys.master_files AS mf
CROSS APPLY 
    sys.dm_os_volume_stats(mf.database_id, mf.file_id) AS vs
WHERE 
    vs.volume_mount_point LIKE 'C:\'
GROUP BY 
    vs.volume_mount_point, vs.total_bytes, vs.available_bytes;
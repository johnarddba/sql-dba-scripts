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
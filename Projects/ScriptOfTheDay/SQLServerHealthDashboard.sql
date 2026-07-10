SELECT
    @@SERVERNAME AS ServerName,
    SERVERPROPERTY('Edition') AS Edition,
    SERVERPROPERTY('ProductVersion') AS ProductVersion,
    SERVERPROPERTY('ProductLevel') AS ProductLevel,
    SERVERPROPERTY('EngineEdition') AS EngineEdition,
    sqlserver_start_time AS SQLServerStartTime,
    DATEDIFF(HOUR, sqlserver_start_time, GETDATE()) AS UptimeHours,
    cpu_count,
    scheduler_count,
    hyperthread_ratio,
    physical_memory_kb / 1024 AS PhysicalMemoryMB,
    committed_kb / 1024 AS SQLMemoryUsedMB,
    committed_target_kb / 1024 AS TargetMemoryMB
FROM sys.dm_os_sys_info;



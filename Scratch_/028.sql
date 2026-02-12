--SQL Script: Check AG Lag and Potential Data Loss


SELECT 
    ar.replica_server_name, 
    adc.database_name, 
    ag.name AS ag_name, 
    drs.readiness_desc, 
    drs.synchronization_state_desc, 
    drs.last_commit_time AS secondary_last_commit_time,
    DATEDIFF(second, drs.last_commit_time, GETDATE()) AS seconds_behind_primary,
    drs.log_send_queue_size -- Data in KB not yet sent to secondary
FROM sys.dm_hadr_database_replica_states drs
JOIN sys.availability_replicas ar ON drs.replica_id = ar.replica_id
JOIN sys.availability_groups ag ON ar.group_id = ag.group_id
JOIN sys.availability_databases_cluster adc ON drs.group_database_id = adc.group_database_id
WHERE drs.is_local = 0; -- Shows remote replicas



/*
Interpreting the Results
seconds_behind_primary: If this number is high, it confirms the Foglight "potential data loss" alarm is valid.

log_send_queue_size: If this number is large, your Network or Disk I/O on the secondary is likely the bottleneck. The Primary is waiting to send the logs, or the Secondary is too slow to write them.

synchronization_state_desc: If it says SYNCHRONIZING, a small lag is normal for Asynchronous mode. If it says NOT SYNCHRONIZING, you have a connection failure.


*/
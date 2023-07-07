SELECT 
  wait_type 
, waiting_tasks_count
, signal_wait_time_ms
, wait_time_ms
, SysDateTime() AS StartTime
INTO 
  #WaitStatsBefore 
FROM 
  sys.dm_os_wait_stats 
WHERE 
  wait_type NOT IN ('SLEEP_TASK','BROKER_EVENTHANDLER','XE_DISPATCHER_WAIT','BROKER_RECEIVE_WAITFOR', 'CLR_AUTO_EVENT', 'CLR_MANUAL_EVENT','REQUEST_FOR_DEADLOCK_SEARCH','SQLTRACE_INCREMENTAL_FLUSH_SLEEP','SQLTRACE_BUFFER_FLUSH','LAZYWRITER_SLEEP','XE_TIMER_EVENT','XE_DISPATCHER_WAIT','FT_IFTS_SCHEDULER_IDLE_WAIT','LOGMGR_QUEUE','CHECKPOINT_QUEUE', 'BROKER_TO_FLUSH', 'BROKER_TASK_STOP', 'BROKER_EVENTHANDLER', 'SLEEP_TASK', 'WAITFOR', 'DBMIRROR_DBM_MUTEX', 'DBMIRROR_EVENTS_QUEUE', 'DBMIRRORING_CMD', 'DISPATCHER_QUEUE_SEMAPHORE','BROKER_RECEIVE_WAITFOR', 'CLR_AUTO_EVENT', 'DIRTY_PAGE_POLL', 'HADR_FILESTREAM_IOMGR_IOCOMPLETION', 'ONDEMAND_TASK_QUEUE', 'FT_IFTSHC_MUTEX', 'CLR_MANUAL_EVENT', 'SP_SERVER_DIAGNOSTICS_SLEEP', 'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP', 'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP','CLR_SEMAPHORE','DBMIRROR_WORKER_QUEUE','SP_SERVER_DIAGNOSTICS_SLEEP','HADR_CLUSAPI_CALL','HADR_LOGCAPTURE_WAIT','HADR_NOTIFICATION_DEQUEUE','HADR_TIMER_TASK','HADR_WORK_QUEUE','REDO_THREAD_PENDING_WORK','UCS_SESSION_REGISTRATION','BROKER_TRANSMITTER','SLEEP_SYSTEMTASK','QDS_SHUTDOWN_QUEUE');--These are a series of irrelevant wait stats.
 
WAITFOR DELAY '00:00:15'; --15 seconds
 
SELECT 
  a.wait_type 
, a.signal_wait_time_ms - b.signal_wait_time_ms AS CPUDiff 
, (a.wait_time_ms - b.wait_time_ms) - (a.signal_wait_time_ms - b.signal_wait_time_ms) AS ResourceDiff
, a.waiting_tasks_count - b.waiting_tasks_count AS waiting_tasks_diff
, CAST(CAST(a.wait_time_ms - b.wait_time_ms AS FLOAT) / (a.waiting_tasks_count - b.waiting_tasks_count) AS DECIMAL(10,1)) AS AverageDurationMS
, a.max_wait_time_ms max_wait_all_timeMS
, DATEDIFF(ms,StartTime, SysDateTime()) AS DurationSeconds
FROM 
  sys.dm_os_wait_stats a 
    INNER JOIN 
  #WaitStatsBefore b ON a.wait_type = b.wait_type 
WHERE 
  a.signal_wait_time_ms <> b.signal_wait_time_ms
    OR 
  a.wait_time_ms <> b.wait_time_ms
ORDER BY 3 DESC;
SELECT
    r.session_id,
    s.login_name,
    r.status,
    r.command,
    r.cpu_time,
    r.total_elapsed_time / 1000 AS elapsed_seconds,
    SUBSTRING(t.text,
        (r.statement_start_offset/2) + 1,
        ((CASE r.statement_end_offset
            WHEN -1 THEN DATALENGTH(t.text)
            ELSE r.statement_end_offset
        END - r.statement_start_offset)/2) + 1) AS running_statement
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s
    ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.session_id <> @@SPID;
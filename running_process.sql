SELECT 
    r.session_id,
    s.login_name,
    s.host_name,
    r.start_time,
    r.status,
    r.total_elapsed_time / 1000 AS [elapsed_time_seconds],
    r.wait_type,
    r.blocking_session_id,
    st.text AS [batch_text],
    SUBSTRING(st.text, (r.statement_start_offset/2) + 1,
    ((CASE r.statement_end_offset
        WHEN -1 THEN DATALENGTH(st.text)
        ELSE r.statement_end_offset END 
            - r.statement_start_offset)/2) + 1) AS [specific_query]
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) st
WHERE s.is_user_process = 1; -- Filters out background system processes
-- Execute this query on the secondary replica
SELECT
    dbcs.database_id,
    DB_NAME(dbcs.database_id) AS database_name,
    dbcs.redo_queue_size,
    dbcs.redo_rate,
    dbcs.log_send_queue_size,
    dbcs.log_send_rate,
    es.session_id,
    es.HOST_NAME,
    es.program_name,
    es.client_interface_name,
    es.login_name,
    es.status,
    es.cpu_time,
    es.memory_usage,
    es.logical_reads,
    es.writes,
    es.READS
FROM
    sys.dm_hadr_database_replica_states AS dbcs
JOIN
    sys.dm_exec_sessions AS es
    ON dbcs.database_id = es.database_id
WHERE
    dbcs.is_primary_replica = 0  -- Ensure this is the secondary replica
    AND dbcs.redo_queue_size > 0  -- Filter for replicas with redo queue size greater than zero indicating lag
ORDER BY
    dbcs.redo_queue_size DESC;  -- Order by redo queue size to identify the largest lag first

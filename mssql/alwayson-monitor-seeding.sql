DECLARE @DatabaseName VARCHAR(128) = NULL; -- leave NULL for all

SELECT	ag.name AS ag_name
		,adc.database_name
		,r.replica_server_name AS replica_name
		,dhas.start_time
		,dhas.completion_time
		,dhas.current_state
		,dhas.failure_state_desc
		,dhas.number_of_attempts
		,dhpss.transfer_rate_bytes_per_second
		,dhpss.transferred_size_bytes
		,dhpss.database_size_bytes
		,dhpss.start_time_utc
		,dhpss.end_time_utc
		,dhpss.estimate_time_complete_utc
		,dhpss.total_disk_io_wait_time_ms
		,dhpss.total_network_wait_time_ms
		,dhpss.failure_code
		,dhpss.failure_message
		,dhpss.failure_time_utc
		,dhpss.is_compression_enabled
FROM sys.availability_groups ag
    JOIN sys.availability_replicas r ON ag.group_id = r.group_id
    JOIN sys.availability_databases_cluster adc ON ag.group_id=adc.group_id
    JOIN sys.dm_hadr_automatic_seeding AS dhas ON dhas.ag_id = ag.group_id
    LEFT JOIN sys.dm_hadr_physical_seeding_stats AS dhpss ON adc.database_name = dhpss.local_database_name
WHERE (adc.database_name = @DatabaseName OR @DatabaseName IS NULL)
ORDER BY dhas.start_time DESC;


--SELECT	r.session_id
--		,r.status
--		,r.command
--		,r.wait_type
--		,r.percent_complete
--		,r.estimated_completion_time
--FROM	sys.dm_exec_requests r
--		JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
--WHERE	r.session_id <> @@SPID
--AND		s.is_user_process = 0
--AND		r.command like 'VDI%';

SELECT	s.session_id
		,DB_NAME(s.database_id) as [database]
		,s.login_name
		,s.status
		,b.event_info
		,s.cpu_time
		,s.memory_usage
		,s.total_scheduled_time
		,s.total_elapsed_time
		,s.reads
		,s.writes
		,s.logical_reads
		,s.transaction_isolation_level
		,s.open_transaction_count
		,DATEDIFF(MILLISECOND,s.last_request_start_time, s.last_request_end_time)
FROM	sys.dm_exec_sessions s
		CROSS APPLY sys.dm_exec_input_buffer (s.session_id, NULL) b
WHERE	s.session_id > 50
ORDER BY DATEDIFF(MILLISECOND,s.last_request_start_time, s.last_request_end_time) DESC

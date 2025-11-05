USE tempdb;

-- tempdb space usage
SELECT
	TRY_CONVERT(INT,(SUM(unallocated_extent_page_count)*1.0/128)) AS FreeSpace_InMB
	,TRY_CONVERT(INT,(SUM(user_object_reserved_page_count)*1.0/128)) AS UserObjects_InMB         -- ex. temp tables or indexes
	,TRY_CONVERT(INT,(SUM(internal_object_reserved_page_count)*1.0/128)) AS InternalObjects_InMB -- ex. work tables or hash joins
	,TRY_CONVERT(INT,(SUM(version_store_reserved_page_count)*1.0/128)) AS VersionStore_InMB
FROM sys.dm_db_file_space_usage;

-- top 10 tempdb consumers
SELECT TOP(10)
	ts.session_id
	,s.host_name
	,s.program_name
	,s.login_name
	,TRY_CONVERT(INT,ts.user_objects_alloc_page_count*1.0/128) AS UserObjects_InMB         -- ex. temp tables or indexes
	,TRY_CONVERT(INT,ts.internal_objects_alloc_page_count*1.0/128) AS InternalObjects_InMB -- ex. work tables or hash joins
	,t.TEXT AS QueryText
FROM sys.dm_db_task_space_usage ts
	INNER JOIN sys.dm_exec_requests r
		ON ts.session_id = r.session_id
		AND ts.request_id = r.request_id
	INNER JOIN sys.dm_exec_sessions s ON ts.session_id = s.session_id
	OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE ts.database_id = 2
	AND user_objects_alloc_page_count + internal_objects_alloc_page_count > 0
ORDER BY UserObjects_InMB DESC, InternalObjects_InMB DESC;

-- version store usage by database
SELECT 
  DB_NAME(database_id) AS 'Database Name',
  reserved_page_count,
  TRY_CONVERT(INT,reserved_page_count*1.0/128) AS reserved_mb
FROM sys.dm_tran_version_store_space_usage
ORDER BY 3 DESC, 2 DESC, 1; 

-- active transactions using row versioning (version store usage)
SELECT
    asdt.transaction_id
    ,asdt.session_id
    --,asdt.transaction_sequence_num
    --,asdt.commit_sequence_num
	,DB_NAME(s.database_id) AS database_name
    ,s.host_name
    ,s.program_name
    ,s.login_name
    ,s.status
    ,asdt.is_snapshot                                                            -- transaction is using snapshot isolation
	,s.is_user_process                                                           -- user-initiated session
    ,s.open_transaction_count                                                    -- usually 1 - higher values can indicate transaction nesting or batch mode use
    ,asdt.elapsed_time_seconds                                                   -- how long the snapshot transaction has been active
    --,t.transaction_begin_time
	,DATEDIFF(SS,t.transaction_begin_time,GETDATE()) as transaction_time_seconds -- how long the transaction has been active
    ,s.cpu_time AS cpu_time_ms
    ,TRY_CONVERT(INT,s.memory_usage*1.0/128) AS memory_usage_mb
FROM sys.dm_tran_active_snapshot_database_transactions AS asdt
	INNER JOIN sys.dm_exec_sessions AS s ON asdt.session_id = s.session_id
	LEFT JOIN sys.dm_tran_active_transactions t ON asdt.transaction_id = t.transaction_id
ORDER BY asdt.elapsed_time_seconds DESC, transaction_time_seconds DESC, asdt.session_id;

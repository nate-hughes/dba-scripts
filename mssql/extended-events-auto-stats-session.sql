CREATE EVENT SESSION [TrackAutoStats] ON SERVER 
ADD EVENT sqlserver.auto_stats(
    ACTION(
		sqlserver.client_app_name
		,sqlserver.client_hostname
		,sqlserver.database_id
		,sqlserver.plan_handle
		,sqlserver.session_id
		,sqlserver.sql_text
		,sqlserver.username
	)
    WHERE (
		database_id=6)
	)
ADD TARGET package0.event_file(
	SET filename=N'X:\Audit\TrackAutoStats.xel',max_rollover_files=(10)
)
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF);
GO


SELECT ed.value('(event/@name)[1]', 'nvarchar(100)') AS event_name,
	ed.value('(event/@timestamp)[1]', 'datetime2') AS [timestamp],
	-- ed.value('(event/data[@name="object_id"]/value)[1]', 'int') AS object_id,
	schema_name(o.schema_id) + '.' + o.name AS [table_name],
	-- ed.value('(event/data[@name="status"]/value)[1]', 'nvarchar(100)') AS status,
	-- ed.value('(event/data[@name="index_id"]/value)[1]', 'int') AS index_id,
	s.name AS stats_name,
	CASE WHEN s.auto_created = 1 THEN 'auto-created'
		WHEN s.user_created = 1 THEN 'user-created'
		ELSE 'index'
	END AS stats_type,
	ed.value('(event/data[@name="statistics_list"]/value)[1]', 'nvarchar(100)') AS [status],
	ed.value('(event/data[@name="duration"]/value)[1]', 'bigint') / 1000 AS duration_ms
FROM sys.fn_xe_file_target_read_file('X:\Audit\TrackAutoStats*.xel', NULL, NULL, NULL) AS x
	CROSS APPLY (SELECT CAST(x.event_data AS XML)) AS tab(ed)
	JOIN sys.objects o ON ed.value('(event/data[@name="object_id"]/value)[1]', 'int') = o.object_id
	LEFT JOIN sys.stats s
		ON o.object_id = s.object_id
		AND ed.value('(event/data[@name="index_id"]/value)[1]', 'int') = s.stats_id
WHERE ed.value('(event/data[@name="status"]/value)[1]', 'nvarchar(100)') = 1 -- Updated
ORDER BY [timestamp] DESC;

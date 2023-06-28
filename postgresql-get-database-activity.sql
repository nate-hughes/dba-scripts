SELECT 
    pid
    ,state
	,COALESCE((clock_timestamp() - xact_start),(clock_timestamp() - query_start)) AS age
    ,pg_blocking_pids(pid) as blocked_by
	,COALESCE(wait_event_type = 'Lock', 'f') AS waiting
	,CASE
		WHEN state = 'active' THEN wait_event_type ||'.'|| wait_event
		ELSE ''
	END AS wait_details
    ,datname as database
    ,usename as role
    ,application_name
	,client_addr ||'.'|| client_port AS client
    ,query
FROM pg_stat_activity
WHERE state is not null
ORDER BY
	state
	,COALESCE(xact_start, query_start);

-- check for background statistics updates in progress
SELECT r.session_id,
	r.command,
	r.status,
	r.start_time,
	r.percent_complete,
	t.text AS sql_text
FROM sys.dm_exec_requests r
	JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
	CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.session_id <> @@SPID
	AND (
		r.command LIKE '%STATISTICS%' OR
		t.text LIKE '%UPDATE STATISTICS%' OR
		t.text LIKE '%ALTER STATISTICS%'
	);

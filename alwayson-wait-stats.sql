SELECT	*
FROM	sys.dm_os_wait_stats
WHERE	wait_type LIKE '%hadr%'
ORDER BY wait_time_ms DESC;
/* Execution plan cache */
SELECT	TOP (10)
		sqltext.text AS query
		,querystats.execution_count
		,querystats.max_elapsed_time
		,ISNULL(querystats.total_elapsed_time / 1000 / NULLIF(querystats.execution_count, 0), 0) AS avg_elapsed_time
		,querystats.creation_time
		,querystats.last_execution_time
		,ISNULL(querystats.execution_count / 1000 / NULLIF(DATEDIFF(SECOND, querystats.creation_time, GETDATE()), 0), 0) AS freq_per_second
		,CAST(query_plan AS XML) AS plan_xml
FROM	sys.dm_exec_query_stats as querystats
		CROSS APPLY sys.dm_exec_text_query_plan (querystats.plan_handle, querystats.statement_start_offset, querystats.statement_end_offset) as textplan
		CROSS APPLY sys.dm_exec_sql_text(querystats.sql_handle) AS sqltext 
ORDER BY querystats.max_elapsed_time DESC
OPTION (RECOMPILE);
GO
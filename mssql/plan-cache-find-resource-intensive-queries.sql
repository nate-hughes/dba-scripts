SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

-- CPU
SELECT	TOP 20
		TRY_CONVERT(DECIMAL(28,2), qs.total_worker_time / 1000000.0) AS [Total CPU Time (s)]
		,TRY_CONVERT(NUMERIC(28,2), qs.total_worker_time * 100.0 / qs.total_elapsed_time) AS [% CPU]
		,qs.execution_count
		,TRY_CONVERT(NUMERIC(28,2), qs.total_worker_time / 1000000.0 / qs.execution_count) AS [Average CPU Time (s)]
		,qs.last_execution_time AS [Last Execution]
		,SUBSTRING(
			st.text
			,(qs.statement_start_offset/2) + 1
			,((CASE
					WHEN qs.statement_end_offset = -1 THEN LEN(TRY_CONVERT(NVARCHAR(MAX), st.text)) * 2
					ELSE qs.statement_end_offset
				END - qs.statement_start_offset) / 2) + 1
		) AS [Query]
		,st.text AS [Parent Query]
		,DB_NAME(st.dbid) AS [Database]
		,qp.query_plan
FROM	sys.dm_exec_query_stats qs
		CROSS APPLY sys.dm_exec_sql_text (qs.sql_handle) st
		CROSS APPLY sys.dm_exec_query_plan (qs.plan_handle) qp
WHERE	qs.total_elapsed_time > 0
ORDER BY [Total CPU Time (s)] DESC;

-- I/O
SELECT	TOP 20
		qs.total_logical_reads + qs.total_logical_writes AS [Total IO]
		,(qs.total_logical_reads + qs.total_logical_writes) / qs.execution_count AS [Average IO]
		,qs.execution_count
		,qs.last_execution_time AS [Last Execution]
		,SUBSTRING(
			st.text
			,(qs.statement_start_offset/2) + 1
			,((CASE
					WHEN qs.statement_end_offset = -1 THEN LEN(TRY_CONVERT(NVARCHAR(MAX), st.text)) * 2
					ELSE qs.statement_end_offset
				END - qs.statement_start_offset) / 2) + 1
		) AS [Query]
		,st.text AS [Parent Query]
		,DB_NAME(st.dbid) AS [Database]
		,qp.query_plan
FROM	sys.dm_exec_query_stats qs
		CROSS APPLY sys.dm_exec_sql_text (qs.sql_handle) st
		CROSS APPLY sys.dm_exec_query_plan (qs.plan_handle) qp
WHERE	qs.total_elapsed_time > 0
ORDER BY [Total IO] DESC;

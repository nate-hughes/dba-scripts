SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT	TOP 20
		TRY_CONVERT(NUMERIC(28,2), qs.total_elapsed_time / 1000000.0) AS [Total Elapsed Duration]
		,qs.execution_count
		,TRY_CONVERT(NUMERIC(28,2), qs.total_elapsed_time / qs.execution_count / 1000000.0) AS [Average Elapsed Duration]
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
ORDER BY qs.total_elapsed_time DESC;

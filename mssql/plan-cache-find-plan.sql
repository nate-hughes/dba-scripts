-- Retrieve the TOP # of cached execution plans that contain the 'search text' statement

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @search_text VARCHAR(MAX) = '%' + 'search_text' + '%'
		,@top_n INT = 20;

SELECT	TOP (@top_n)
		st.text AS [SQL]
		,cp.cacheobjtype AS [Object Type in Cache]
		,cp.objtype AS [Object Type]
		,COALESCE(
			DB_NAME(st.dbid)
			,DB_NAME(TRY_CONVERT(INT, pa.value)) + '*'
			,'Resource'
		) AS [Database]
		,cp.usecounts AS [Plan Usage]                                -- Measures plan-level usage
		,qs.execution_count AS [Execution Count]                     -- Measures statement-level execution within the plan
        ,qs.total_elapsed_time / 1000 AS [Total Elapsed Time (ms)]
        ,qs.total_worker_time / 1000 AS [Total CPU Time (ms)]
        ,qs.total_logical_reads AS [Total Logical Reads]
        ,qs.total_logical_writes AS [Total Logical Writes]
		,qp.query_plan
FROM	sys.dm_exec_cached_plans cp
		CROSS APPLY sys.dm_exec_sql_text (cp.plan_handle) st
		CROSS APPLY sys.dm_exec_query_plan (cp.plan_handle) qp
		OUTER APPLY sys.dm_exec_plan_attributes (cp.plan_handle) pa
		JOIN sys.dm_exec_query_stats qs ON cp.plan_handle = qs.plan_handle
WHERE	pa.attribute = 'dbid'
AND		st.text LIKE @search_text
ORDER BY cp.usecounts DESC;

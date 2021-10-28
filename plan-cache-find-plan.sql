SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT	TOP 20
		st.text AS [SQL]
		,cp.cacheobjtype AS [Object Type in Cache]
		,cp.objtype AS [Object Type]
		,COALESCE(
			DB_NAME(st.dbid)
			,DB_NAME(TRY_CONVERT(INT, pa.value)) + '*'
			,'Resource'
		) AS [Database]
		,cp.usecounts AS [Plan Usage]
		,qp.query_plan
FROM	sys.dm_exec_cached_plans cp
		CROSS APPLY sys.dm_exec_sql_text (cp.plan_handle) st
		CROSS APPLY sys.dm_exec_query_plan (cp.plan_handle) qp
		OUTER APPLY sys.dm_exec_plan_attributes (cp.plan_handle) pa
WHERE	pa.attribute = 'dbid'
AND		st.text LIKE '%CREATE PROCEDURE%'
ORDER BY cp.usecounts DESC;

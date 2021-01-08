SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO

SELECT	COALESCE(T1.session_id, T2.session_id) [session_id]
		,S.login_name
		,S.host_name
		,S.program_name
		,S.status
		,S.last_request_start_time
		,S.last_request_end_time
		,DATEDIFF(HOUR,S.last_request_end_time,GETDATE()) AS hours_since_last_run
		,S.open_transaction_count
		--,COALESCE(T1.[Total Allocation User Objects], 0) + T2.[Total Allocation User Objects] [Total Allocation User Objects]
		,COALESCE(T1.[Net Allocation User Objects], 0) + T2.[Net Allocation User Objects] [Net Allocation User Objects]
		--,COALESCE(T1.[Total Allocation Internal Objects], 0) + T2.[Total Allocation Internal Objects] [Total Allocation Internal Objects]
		,COALESCE(T1.[Net Allocation Internal Objects], 0) + T2.[Net Allocation Internal Objects] [Net Allocation Internal Objects]
		--,COALESCE(T1.[Total Allocation], 0) + T2.[Total Allocation] [Total Allocation]
		,COALESCE(T1.[Net Allocation], 0) + T2.[Net Allocation] [Net Allocation]
		--,COALESCE(T1.[Query Text], T2.[Query Text]) [Query Text]
		,T.text [Query Text]
FROM    (
			SELECT	TS.session_id
					,CAST(MAX(TS.user_objects_alloc_page_count) / 128 AS DECIMAL(15,2)) [Total Allocation User Objects]
					,CAST((MAX(TS.user_objects_alloc_page_count) - MAX(TS.user_objects_dealloc_page_count)) / 128 AS DECIMAL(15,2)) [Net Allocation User Objects]
					,CAST(SUM(TS.internal_objects_alloc_page_count) / 128 AS DECIMAL(15,2)) [Total Allocation Internal Objects]
					,CAST((SUM(TS.internal_objects_alloc_page_count) - SUM(TS.internal_objects_dealloc_page_count)) / 128 AS DECIMAL(15,2)) [Net Allocation Internal Objects]
					,CAST((MAX(TS.user_objects_alloc_page_count) + SUM(internal_objects_alloc_page_count)) / 128 AS DECIMAL(15,2)) [Total Allocation]
					,CAST((MAX(TS.user_objects_alloc_page_count)
						+ SUM(TS.internal_objects_alloc_page_count)
						- SUM(TS.internal_objects_dealloc_page_count)
						- MAX(TS.user_objects_dealloc_page_count) ) / 128 AS DECIMAL(15,2)) [Net Allocation]
					--,T.text [Query Text]
					,ER.sql_handle
			FROM	sys.dm_db_task_space_usage TS
					INNER JOIN sys.dm_exec_requests ER
						ON ER.request_id = TS.request_id
						AND ER.session_id = TS.session_id
					--OUTER APPLY sys.dm_exec_sql_text(ER.sql_handle) T
			GROUP BY TS.session_id
					,ER.sql_handle
        ) T1
        RIGHT JOIN (
			SELECT	SS.session_id
					,CAST(MAX(SS.user_objects_alloc_page_count) / 128 AS DECIMAL(15,2)) [Total Allocation User Objects]
					,CAST((MAX(SS.user_objects_alloc_page_count) - MAX(SS.user_objects_dealloc_page_count)) / 128 AS DECIMAL(15,2)) [Net Allocation User Objects]
					,CAST(SUM(SS.internal_objects_alloc_page_count) / 128 AS DECIMAL(15,2)) [Total Allocation Internal Objects]
					,CAST((SUM(SS.internal_objects_alloc_page_count) - SUM(SS.internal_objects_dealloc_page_count)) / 128 AS DECIMAL(15,2)) [Net Allocation Internal Objects]
					,CAST((MAX(SS.user_objects_alloc_page_count) + SUM(internal_objects_alloc_page_count)) / 128 AS DECIMAL(15,2)) [Total Allocation]
					,CAST((MAX(SS.user_objects_alloc_page_count)
						+ SUM(SS.internal_objects_alloc_page_count)
						- SUM(SS.internal_objects_dealloc_page_count)
						- MAX(SS.user_objects_dealloc_page_count)) / 128 AS DECIMAL(15,2)) [Net Allocation]
					--,T.text [Query Text]
					,CN.most_recent_sql_handle
			FROM	sys.dm_db_session_space_usage SS
					LEFT JOIN sys.dm_exec_connections CN ON CN.session_id = SS.session_id
					--OUTER APPLY sys.dm_exec_sql_text(CN.most_recent_sql_handle) T
			GROUP BY SS.session_id
					,CN.most_recent_sql_handle
	) T2 ON T1.session_id = T2.session_id
	OUTER APPLY sys.dm_exec_sql_text(COALESCE(T1.sql_handle,T2.most_recent_sql_handle)) T
	JOIN sys.dm_exec_sessions S ON s.session_id = COALESCE(T1.session_id, T2.session_id)
WHERE	COALESCE(T1.[Net Allocation],0) + COALESCE(T2.[Net Allocation],0) > 0
ORDER BY [Net Allocation] DESC;


--SELECT	TS.session_id
--		,CAST((TS.user_objects_alloc_page_count) / 128 AS DECIMAL(15,2)) [Total Allocation User Objects]
--		,CAST(((TS.user_objects_alloc_page_count) - (TS.user_objects_dealloc_page_count)) / 128 AS DECIMAL(15,2)) [Net Allocation User Objects]
--		,CAST((TS.internal_objects_alloc_page_count) / 128 AS DECIMAL(15,2)) [Total Allocation Internal Objects]
--		,CAST(((TS.internal_objects_alloc_page_count) - (TS.internal_objects_dealloc_page_count)) / 128 AS DECIMAL(15,2)) [Net Allocation Internal Objects]
--		,CAST(((TS.user_objects_alloc_page_count) + (internal_objects_alloc_page_count)) / 128 AS DECIMAL(15,2)) [Total Allocation]
--		,CAST(((TS.user_objects_alloc_page_count)
--			+ (TS.internal_objects_alloc_page_count)
--			- (TS.internal_objects_dealloc_page_count)
--			- (TS.user_objects_dealloc_page_count) ) / 128 AS DECIMAL(15,2)) [Net Allocation]
--		,T.text [Query Text]
--		,P.query_plan
--FROM	sys.dm_db_task_space_usage TS
--		INNER JOIN sys.dm_exec_requests ER
--			ON ER.request_id = TS.request_id
--			AND ER.session_id = TS.session_id
--		OUTER APPLY sys.dm_exec_sql_text(ER.sql_handle) T
--		OUTER APPLY sys.dm_exec_query_plan (ER.plan_handle) P
--WHERE	TS.session_id = 274

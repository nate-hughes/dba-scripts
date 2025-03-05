DECLARE @SPID INT = 390;

SELECT	qs.percent_complete
		,qs.estimated_completion_time
		,qs.session_id
		,qs.scheduler_id
		,qs.blocking_session_id
		,qs.status
		,qs.command
		,qs.wait_time
		,qs.wait_type
		,qs.last_wait_type
		,qs.wait_resource
		,ST.text
		,es.host_name
		,es.program_name
FROM	sys.dm_exec_requests qs
		LEFT JOIN sys.dm_exec_sessions es ON (qs.session_id = es.session_id)
		CROSS APPLY sys.dm_exec_sql_text (qs.sql_handle) ST
WHERE	qs.session_id = @SPID;

;WITH agg AS (
	SELECT	SUM(qp.[row_count]) AS [RowsProcessed]
			,SUM(qp.[estimate_row_count]) AS [TotalRows]
			,MAX(qp.last_active_time) - MIN(qp.first_active_time) AS [ElapsedMS]
			,MAX(IIF(qp.[close_time] = 0 AND qp.[first_row_time] > 0, [physical_operator_name], N'<Transition>')) AS [CurrentStep]
	FROM	sys.dm_exec_query_profiles qp
	WHERE	/*qp.[physical_operator_name] IN (N'Table Scan', N'Clustered Index Scan', N'Index Scan',  N'Sort')
	AND		*/qp.[session_id] = @SPID
)
,comp AS
(
     SELECT	*
			,([TotalRows] - [RowsProcessed]) AS [RowsLeft]
			,([ElapsedMS] / 1000.0) AS [ElapsedSeconds]
     FROM	agg
)
SELECT	[CurrentStep]
		,[TotalRows]
		,[RowsProcessed]
		,[RowsLeft]
		,CONVERT(DECIMAL(5,2), (([RowsProcessed] * 1.0) / [TotalRows]) * 100) AS [PercentComplete]
		,[ElapsedSeconds]
		,(([ElapsedSeconds] / [RowsProcessed]) * [RowsLeft]) AS [EstimatedSecondsLeft]
		,DATEADD(SECOND, (([ElapsedSeconds] / [RowsProcessed]) * [RowsLeft]), GETDATE()) AS [EstimatedCompletionTime]
FROM	comp;

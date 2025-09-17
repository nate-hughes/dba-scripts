-- Modified FindSPQueries_UsingQueryStore.sql
-- https://github.com/erinstellato/SQL-Server-Query-Store/blob/master/FindSPQueries_UsingQueryStore.sql#L56

DECLARE @proc NVARCHAR(200) = 'Salesforce_Reporting_January2018'
		,@limit_to_last_hour BIT = 0
		,@show_aggregate_only BIT = 1;

-- Check to see what queries exist for the SP
SELECT
	[qsq].[query_id] 
	,[qsp].[plan_id] 
	,[qsq].[object_id] 
	,[qst].[query_sql_text]
	,[qsp].[is_forced_plan]
	,ConvertedPlan = TRY_CONVERT(XML, [qsp].[query_plan])
FROM [sys].[query_store_query] [qsq] 
	JOIN [sys].[query_store_query_text] [qst] ON [qsq].[query_text_id] = [qst].[query_text_id]
	JOIN [sys].[query_store_plan] [qsp] ON [qsq].[query_id] = [qsp].[query_id]
WHERE [qsq].[object_id] = OBJECT_ID(@proc);

-- Check runtime stats for each query in the SP
-- Duration & CPU in milliseconds
-- Memory Grant, Reads, & TempDb in MB
SELECT
	[qsq].[query_id]
	,[qsp].[plan_id]
	,[qsq].[object_id]
	,[rs].[runtime_stats_interval_id]
	,[rsi].[start_time]
	,[rsi].[end_time]
	,[rs].[count_executions]
	,[rs].[avg_rowcount]
	,ROUND([rs].[avg_duration] * 0.001,0) AS [avg_duration]
	,ROUND([rs].[avg_cpu_time] * 0.001,0) AS [avg_cpu_time]
	,ROUND([rs].[avg_query_max_used_memory] / 128,0) AS [avg_query_max_used_memory]
	,ROUND([rs].[avg_logical_io_reads] / 128,0) AS [avg_logical_io_reads]
	,ROUND([rs].[avg_physical_io_reads] / 128,0) AS [avg_physical_io_reads]
	,ROUND([rs].[avg_tempdb_space_used] / 128,0) AS [avg_tempdb_space_used]
	,[qst].[query_sql_text]
	,ConvertedPlan = TRY_CONVERT(XML, [qsp].[query_plan])
FROM [sys].[query_store_query] [qsq] 
	JOIN [sys].[query_store_query_text] [qst] ON [qsq].[query_text_id] = [qst].[query_text_id]
	JOIN [sys].[query_store_plan] [qsp] ON [qsq].[query_id] = [qsp].[query_id]
	JOIN [sys].[query_store_runtime_stats] [rs] ON [qsp].[plan_id] = [rs].[plan_id]
	JOIN [sys].[query_store_runtime_stats_interval] [rsi] ON [rs].[runtime_stats_interval_id] = [rsi].[runtime_stats_interval_id]
WHERE [qsq].[object_id] = OBJECT_ID(@proc)
	AND ([rs].[last_execution_time] > DATEADD(HOUR, -1, GETUTCDATE()) OR @limit_to_last_hour = 0)
	AND [rs].[execution_type] = 0
	AND @show_aggregate_only = 0
ORDER BY [qsq].[query_id]
	,[qsp].[plan_id]
	,[rs].[runtime_stats_interval_id];

-- Check aggregate runtime stats for each query in the SP
-- Duration & CPU in milliseconds
-- Memory Grant, Reads, & TempDb in MB
SELECT
	[qsq].[query_id] 
	,[qsp].[plan_id]
	,OBJECT_NAME([qsq].[object_id]) AS [ObjectName]
	,SUM([rs].[count_executions]) AS [TotalExecutions]
	,AVG([rs].[avg_rowcount]) AS [Avg_RowCount]
	,ROUND(AVG([rs].[avg_duration]) * 0.001,0) AS [Avg_Duration]
	,ROUND(AVG([rs].[avg_cpu_time]) * 0.001,0) AS [Avg_CPU]
	,ROUND(AVG([rs].[avg_query_max_used_memory]) / 128,0) AS [Avg_MemoryGrant]
	,ROUND(AVG([rs].[avg_logical_io_reads]) / 128,0) AS [Avg_LogicalReads]
	,ROUND(AVG([rs].[avg_physical_io_reads]) / 128,0) AS [Avg_PhysicalReads]
	,ROUND(AVG([rs].[avg_tempdb_space_used]) / 128,0) AS [Avg_TempDb]
	,MIN([qst].[query_sql_text]) AS[Query]
FROM [sys].[query_store_query] [qsq] 
	JOIN [sys].[query_store_query_text] [qst] ON [qsq].[query_text_id] = [qst].[query_text_id]
	JOIN [sys].[query_store_plan] [qsp] ON [qsq].[query_id] = [qsp].[query_id]
	JOIN [sys].[query_store_runtime_stats] [rs] ON [qsp].[plan_id] = [rs].[plan_id]
	JOIN [sys].[query_store_runtime_stats_interval] [rsi] ON [rs].[runtime_stats_interval_id] = [rsi].[runtime_stats_interval_id]
WHERE [qsq].[object_id] = OBJECT_ID(@proc)
	AND ([rs].[last_execution_time] > DATEADD(HOUR, -1, GETUTCDATE()) OR @limit_to_last_hour = 0) 
	AND [rs].[execution_type] = 0
	AND @show_aggregate_only = 1
GROUP BY [qsq].[query_id]
	,[qsp].[plan_id]
	,OBJECT_NAME([qsq].[object_id])
ORDER BY AVG([rs].[avg_cpu_time]) DESC;


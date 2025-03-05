-- Retrieve the highest variability statements from Query Store within the last hour

DECLARE @FromTime DATETIME = DATEADD(HOUR, -1, GETUTCDATE()) 
		,@ToTime DATETIME = GETUTCDATE();

SELECT	qsp.query_id
		,CASE
			WHEN qsq.object_id = 0 THEN N'Ad-hoc'
			ELSE OBJECT_NAME(qsq.object_id) 
		END AS sproc
		,qsqt.query_sql_text
		,qsrt.min_query_max_used_memory / 128 AS min_max_used_memory_mb
		,qsrt.max_query_max_used_memory / 128 AS max_max_used_memory_mb
		,((qsrt.max_query_max_used_memory) - (qsrt.min_query_max_used_memory)) / 128 AS max_used_memory_diff
		,qsrt.min_tempdb_space_used
		,qsrt.max_tempdb_space_used
		,(qsrt.max_tempdb_space_used - qsrt.min_tempdb_space_used) AS tempdb_space_diff
		,TRY_CONVERT(XML, qsp.query_plan) AS [QueryPlan_XML]
	FROM sys.query_store_query qsq 
	INNER JOIN sys.query_store_query_text qsqt ON qsqt.query_text_id = qsq.query_text_id
	INNER JOIN sys.query_store_plan qsp ON qsp.query_id = qsq.query_id
	INNER JOIN sys.query_store_runtime_stats qsrt ON qsrt.plan_id = qsp.plan_id
	INNER JOIN sys.query_store_runtime_stats_interval qsrsi ON qsrsi.runtime_stats_interval_id = qsrt.runtime_stats_interval_id
WHERE	qsrsi.start_time >= @FromTime AND qsrsi.start_time < @ToTime
AND		(
			(qsrt.max_query_max_used_memory*8) - (qsrt.min_query_max_used_memory*8) > 51200
			OR (qsrt.max_tempdb_space_used - qsrt.min_tempdb_space_used) > 1000
		);

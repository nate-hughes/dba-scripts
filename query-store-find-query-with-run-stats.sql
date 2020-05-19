/***** SCRIPT NEEDS EITHER @proc OR @sql_text TO WORK *****/
DECLARE @proc VARCHAR(200) = 'SprocName'
		,@sql_text VARCHAR(MAX) = NULL;

SELECT  q.query_id,
		q.last_execution_time,
		OBJECT_NAME(q.object_id) AS sproc,
		qt.query_sql_text,
		qsrt.avg_duration,
		qsrt.count_executions,
		qsrt.avg_cpu_time,
		qsrt.avg_logical_io_reads,
		qsrtsi.start_time		
FROM    sys.query_store_query q
		INNER JOIN sys.query_store_query_text qt ON qt.query_text_id = q.query_text_id
		INNER JOIN sys.query_store_plan qsp ON qsp.query_id = q.query_id
		INNER JOIN sys.query_store_runtime_stats qsrt ON qsrt.plan_id = qsp.plan_id
		INNER JOIN sys.query_store_runtime_stats_interval qsrtsi ON qsrtsi.runtime_stats_interval_id = qsrt.runtime_stats_interval_id
WHERE (@proc IS NULL OR q.object_id = OBJECT_ID(@proc))
AND	(@sql_text IS NULL OR qt.query_sql_text LIKE '%' + @sql_text + '%')
ORDER BY q.query_id
	,q.last_execution_time DESC;
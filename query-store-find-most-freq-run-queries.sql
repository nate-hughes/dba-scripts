DECLARE @Top INT = 5
		,@FromTime DATETIME = '2019-01-01 00:00:00'
		,@ToTime DATETIME = GETDATE();

SELECT TOP(@Top) qsp.query_id,
		OBJECT_NAME(qsq.object_id) AS sproc,
        qsqt.query_sql_text,
		SUM(qsrt.count_executions) as count_executions
	FROM sys.query_store_query qsq 
	INNER JOIN sys.query_store_query_text qsqt ON qsqt.query_text_id = qsq.query_text_id
	INNER JOIN sys.query_store_plan qsp ON qsp.query_id = qsq.query_id
	INNER JOIN sys.query_store_runtime_stats qsrt ON qsrt.plan_id = qsp.plan_id
	INNER JOIN sys.query_store_runtime_stats_interval qsrsi ON qsrsi.runtime_stats_interval_id = qsrt.runtime_stats_interval_id
WHERE qsrsi.start_time >= @FromTime AND qsrsi.start_time < @ToTime
GROUP BY qsp.query_id,
		OBJECT_NAME(qsq.object_id),
        qsqt.query_sql_text
ORDER BY SUM(qsrt.count_executions) DESC;

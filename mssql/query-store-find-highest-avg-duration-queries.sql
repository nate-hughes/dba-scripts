-- Retrieve the top 5 highest average duration statements from Query Store within the last hour

DECLARE @Top INT = 5
		,@FromTime DATETIME = DATEADD(HOUR, -1, GETUTCDATE()) 
		,@ToTime DATETIME = GETUTCDATE();

SELECT TOP(@Top) qsp.query_id,
		CASE
			WHEN qsq.object_id = 0 THEN N'Ad-hoc'
			ELSE OBJECT_NAME(qsq.object_id) 
		END AS sproc,
        qsqt.query_sql_text,
		AVG(qsrt.avg_duration) as avg_duration
	FROM sys.query_store_query qsq 
	INNER JOIN sys.query_store_query_text qsqt ON qsqt.query_text_id = qsq.query_text_id
	INNER JOIN sys.query_store_plan qsp ON qsp.query_id = qsq.query_id
	INNER JOIN sys.query_store_runtime_stats qsrt ON qsrt.plan_id = qsp.plan_id
	INNER JOIN sys.query_store_runtime_stats_interval qsrsi ON qsrsi.runtime_stats_interval_id = qsrt.runtime_stats_interval_id
WHERE qsrsi.start_time >= @FromTime AND qsrsi.start_time < @ToTime
GROUP BY qsp.query_id,
		qsq.object_id,
        qsqt.query_sql_text
ORDER BY AVG(qsrt.avg_duration) DESC;
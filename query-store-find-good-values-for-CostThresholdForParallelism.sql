/********************************************************************************
NEED TO COPY IN query_ids FROM query-store-find-most-freq-run-queries.sql
********************************************************************************/

DECLARE @Top INT = 5
		,@FromTime DATETIME = '2018-12-17 00:00:00'
		,@ToTime DATETIME = GETDATE();
		
SELECT * FROM 
(SELECT qsq.query_id, qsrt.avg_duration, 
	5+10*(DATEDIFF(HOUR, @FromTime, qsrsi.start_time)) AS CostThreshold
	FROM sys.query_store_query qsq 
	INNER JOIN sys.query_store_query_text qsqt ON qsqt.query_text_id = qsq.query_text_id
	INNER JOIN sys.query_store_plan qsp ON qsp.query_id = qsq.query_id
	INNER JOIN sys.query_store_runtime_stats qsrt ON qsrt.plan_id = qsp.plan_id
	INNER JOIN sys.query_store_runtime_stats_interval qsrsi ON qsrsi.runtime_stats_interval_id = qsrt.runtime_stats_interval_id
WHERE qsq.query_id IN (17, 18, 62551, 51, 62578)
	AND qsrsi.start_time >= @FromTime AND qsrsi.start_time < @ToTime
) AS RawStats
PIVOT (
	avg(avg_duration)
	FOR query_id IN ([17], [18], [62551], [51], [62578])
) AS QueryPerformanceOverTime

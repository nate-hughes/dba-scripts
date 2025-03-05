-- Retrieve queries executed in the last hour with multiple plans

DECLARE @FromTime DATETIME = DATEADD(HOUR, -1, GETUTCDATE())
		,@ToTime DATETIME = GETUTCDATE();

SELECT	qsp.query_id,
		COUNT(qsp.plan_id) AS plan_count,
		CASE
			WHEN qsq.object_id = 0 THEN N'Ad-hoc'
			ELSE OBJECT_NAME(qsq.object_id) 
		END AS sproc,
        qsqt.query_sql_text,
		MAX(DATEADD(MINUTE,-(DATEDIFF(MINUTE, GETDATE(), GETUTCDATE())),qsp.last_execution_time)) AS last_execution_time
	FROM sys.query_store_query qsq 
	INNER JOIN sys.query_store_query_text qsqt ON qsqt.query_text_id = qsq.query_text_id
	INNER JOIN sys.query_store_plan qsp ON qsp.query_id = qsq.query_id
WHERE qsp.last_execution_time >= @FromTime AND qsp.last_execution_time < @ToTime
GROUP BY qsp.query_id,
		qsq.object_id,
        qsqt.query_sql_text
HAVING COUNT(qsp.plan_id) > 1
ORDER BY last_execution_time DESC;
GO

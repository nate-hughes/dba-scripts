DROP TABLE IF EXISTS #running;
DROP TABLE IF EXISTS #duration;

-- find currently executing packages in SSIS.Catalog
SELECT	ISNULL(CONVERT(BIGINT, DATEDIFF(MILLISECOND, [start_time], ISNULL([end_time], SYSDATETIMEOFFSET()))) / 1000, 0) AS dur_sec
		,execution_id
		,folder_name
		,project_name
		,package_name
		,executed_as_name
		,CASE status
			WHEN 1 THEN 'CREATED'
			WHEN 2 THEN 'RUNNING'
			WHEN 3 THEN 'CANCELED'
			WHEN 4 THEN 'FAILED'
			WHEN 5 THEN 'PENDING'
			WHEN 6 THEN 'ENDED UNEXPECTANTLY'
			WHEN 7 THEN 'SUCCEEDED'
			WHEN 8 THEN 'STOPPING'
			WHEN 9 THEN 'COMPLETED'
		END AS status
		,start_time
		,end_time
		,caller_name
INTO	#running
FROM	SSISDB.catalog.executions
WHERE	end_time IS NULL;

-- find durations over the past month for currently executing packages
SELECT	package_name
		,MIN(CONVERT(BIGINT, DATEDIFF(MILLISECOND, [start_time], ISNULL([end_time], SYSDATETIMEOFFSET()))) / 1000) AS min_dur_sec
		,MAX(CONVERT(BIGINT, DATEDIFF(MILLISECOND, [start_time], ISNULL([end_time], SYSDATETIMEOFFSET()))) / 1000) AS max_dur_sec
		,AVG(CONVERT(BIGINT, DATEDIFF(MILLISECOND, [start_time], ISNULL([end_time], SYSDATETIMEOFFSET()))) / 1000) AS avg_dur_sec
INTO	#duration
FROM	SSISDB.catalog.executions
WHERE	package_name IN (
			SELECT	package_name
			FROM	#running
		)
AND		start_time >= DATEADD(MONTH,-1,CONVERT(DATE,GETDATE()))
AND		status = 7
GROUP BY package_name;

-- show currently executing packages along with expected durations
SELECT	r.*
		,d.min_dur_sec AS hist_min_dur_sec
		,d.max_dur_sec AS hist_max_dur_sec
		,d.avg_dur_sec AS hist_avg_dur_sec
FROM	#running r
		LEFT JOIN #duration d ON r.package_name = d.package_name
ORDER BY r.dur_sec DESC;

-- use the following to kill runaway SSIS packages
/*
USE SSISDB;
GO
EXEC catalog.stop_operation @operation_id = [r.execution_id];
GO
*/

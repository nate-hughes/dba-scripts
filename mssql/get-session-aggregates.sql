
DECLARE @StartTime DATETIME;
--SET @StartTime = '7/24/2019 12:00:00'; -- if set, only shows connections with a last_request_start_time >= @StartTime

DROP TABLE IF EXISTS #sessions
SELECT * INTO #sessions FROM sys.dm_exec_sessions WHERE @StartTime IS NULL OR last_request_start_time >= @StartTime;

-- user sessions per database
WITH status_count AS (
	SELECT	DB_NAME(database_id) AS database_name
			,status
			,COUNT(*) AS sessions
	FROM	#sessions
	WHERE	is_user_process = 1
	GROUP BY database_id
			,status
)
SELECT	c1.database_name
		,MAX(CASE WHEN c1.status = 'Running' THEN c1.sessions ELSE 0 END) as Running
		,MAX(CASE WHEN c1.status = 'Sleeping' THEN c1.sessions ELSE 0 END) as Sleeping
		,MAX(CASE WHEN c1.status = 'Dormant' THEN c1.sessions ELSE 0 END) as Dormant
		,MAX(CASE WHEN c1.status = 'Preconnect' THEN c1.sessions ELSE 0 END) as Preconnect
		,SUM(c1.sessions) as Total
FROM	status_count c1
		JOIN (
			SELECT	database_name
					,SUM(sessions) as sessions
					,ROW_NUMBER() OVER (ORDER BY SUM(sessions) DESC) as orderby
			FROM	status_count
			GROUP BY database_name
		) c2 ON c1.database_name = c2.database_name
GROUP BY c1.database_name
		,c2.orderby
ORDER BY c2.orderby;

-- user sessions per host
WITH status_count AS (
	SELECT	host_name
			,status
			,COUNT(*) AS sessions
	FROM	#sessions
	WHERE	is_user_process = 1
	GROUP BY host_name
			,status
)
SELECT	c1.host_name
		,MAX(CASE WHEN c1.status = 'Running' THEN c1.sessions ELSE 0 END) as Running
		,MAX(CASE WHEN c1.status = 'Sleeping' THEN c1.sessions ELSE 0 END) as Sleeping
		,MAX(CASE WHEN c1.status = 'Dormant' THEN c1.sessions ELSE 0 END) as Dormant
		,MAX(CASE WHEN c1.status = 'Preconnect' THEN c1.sessions ELSE 0 END) as Preconnect
		,SUM(c1.sessions) as Total
FROM	status_count c1
		JOIN (
			SELECT	host_name
					,SUM(sessions) as sessions
					,ROW_NUMBER() OVER (ORDER BY SUM(sessions) DESC) as orderby
			FROM	status_count
			GROUP BY host_name
		) c2 ON c1.host_name = c2.host_name
GROUP BY c1.host_name
		,c2.orderby
ORDER BY c2.orderby;

-- user sessions per login
WITH status_count AS (
	SELECT	login_name
			,status
			,COUNT(*) AS sessions
	FROM	#sessions
	WHERE	is_user_process = 1
	GROUP BY login_name
			,status
)
SELECT	c1.login_name
		,MAX(CASE WHEN c1.status = 'Running' THEN c1.sessions ELSE 0 END) as Running
		,MAX(CASE WHEN c1.status = 'Sleeping' THEN c1.sessions ELSE 0 END) as Sleeping
		,MAX(CASE WHEN c1.status = 'Dormant' THEN c1.sessions ELSE 0 END) as Dormant
		,MAX(CASE WHEN c1.status = 'Preconnect' THEN c1.sessions ELSE 0 END) as Preconnect
		,SUM(c1.sessions) as Total
FROM	status_count c1
		JOIN (
			SELECT	login_name
					,SUM(sessions) as sessions
					,ROW_NUMBER() OVER (ORDER BY SUM(sessions) DESC) as orderby
			FROM	status_count
			GROUP BY login_name
		) c2 ON c1.login_name = c2.login_name
GROUP BY c1.login_name
		,c2.orderby
ORDER BY c2.orderby;

-- user database session resource consumption
SELECT	login_name
		,DB_NAME(database_id) as database_name
		,SUM(cpu_time) as cpu_time
		,MAX(last_request_end_time) as last_request_end_time
		,SUM(memory_usage) * 8 as memory_kb -- memory_usage: Number of 8-KB pages of memory
		,SUM(reads) as reads
		,SUM(writes) as writes
		,SUM(open_transaction_count) as open_transaction_count
FROM	#sessions
WHERE	is_user_process = 1
AND		database_id > 4
GROUP BY login_name
		,database_id
ORDER BY cpu_time DESC;
--ORDER BY memory_kb DESC;
--ORDER BY writes DESC;
--ORDER BY open_transaction_count DESC;

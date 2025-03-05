-- Are my actual worker threads exceeding the sp_configure 'max worker threads' value?
-- https://techcommunity.microsoft.com/t5/Premier-Field-Engineering/Are-my-actual-worker-threads-exceeding-the-sp-configure-max/ba-p/370506

-- Number of Availability Groups
SELECT count(*) AS NumAvailabilityGroups
FROM sys.availability_groups

-- Find Max Worker Threads
--exec sp_server_diagnostics 
-- <queryProcessing maxWorkers="960" workersCreated="1136" workersIdle="246"


SELECT is_preemptive
	,STATE
	,last_wait_type
	,count(*) AS NumWorkers
FROM sys.dm_os_workers
WHERE	state = 'running'
GROUP BY STATE
	,last_wait_type
	,is_preemptive
ORDER BY count(*) DESC


SELECT is_preemptive
	,STATE
	,last_wait_type
	,count(*) AS NumWorkers
FROM sys.dm_os_workers
GROUP BY STATE
	,last_wait_type
	,is_preemptive
ORDER BY count(*) DESC


SELECT last_wait_type
	,count(*) AS NumRequests
FROM sys.dm_exec_requests
GROUP BY last_wait_type
ORDER BY count(*) DESC


SELECT is_user_process
	,count(*) AS RequestCount
FROM sys.dm_exec_sessions s
INNER JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
GROUP BY is_user_process

;WITH cte
AS (
	SELECT s.is_user_process
		,w.worker_address
		,w.is_preemptive
		,w.STATE
		,r.STATUS
		,t.task_state
		,r.command
		,w.last_wait_type
		,t.session_id
		,t.exec_context_id
		,t.request_id
	FROM sys.dm_exec_sessions s
	INNER JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
	INNER JOIN sys.dm_os_tasks t ON r.task_address = t.task_address
	INNER JOIN sys.dm_os_workers w ON t.worker_address = w.worker_address
	WHERE s.is_user_process = 0
	)
SELECT is_user_process
	,command
	,last_wait_type
	,count(*) AS cmd_cnt
FROM cte
GROUP BY is_user_process
	,command
	,last_wait_type
ORDER BY cmd_cnt DESC

SELECT max_workers_count
FROM sys.dm_os_sys_info

SELECT	*
FROM sys.dm_os_threads t
	JOIN sys.dm_os_schedulers s	ON s.scheduler_address = t.scheduler_address
	JOIN sys.dm_os_workers w ON w.worker_address = s.active_worker_address
WHERE	w.state = 'RUNNING'


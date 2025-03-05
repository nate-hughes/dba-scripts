
-- SOS_SCHEDULER_YIELD: wait in queue after task voluntarily yields scheduler for other tasks to execute
-- High SIGNAL_WAIT_TIME_MS waits might mean potential CPU contention
SELECT	*
		,CONVERT(NUMERIC(9,2),signal_wait_time_ms * 1.0 / wait_time_ms * 100) Pct_signal_wait_time_ms
FROM	sys.dm_os_wait_stats
WHERE	wait_type IN ('SOS_SCHEDULER_YIELD');

-- RUNNING: task is executing
-- RUNNABLE: task is ready to execute, it's in the queue
-- High RUNNABLE states might mean potential CPU contention
SELECT	task_state, COUNT(*)
FROM	sys.dm_os_tasks
WHERE	task_state IN ('RUNNING', 'RUNNABLE')
GROUP BY task_state;

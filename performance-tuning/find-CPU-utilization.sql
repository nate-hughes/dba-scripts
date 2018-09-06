DECLARE @ts_now BIGINT
       ,@span   INT = 30; -- number minutes of recent hist to return

SELECT  @ts_now = cpu_ticks / (cpu_ticks / ms_ticks)
FROM    sys.dm_os_sys_info;

SELECT  TOP (@span)
        y.SQLProcessUtilization                              AS [SQL Server CPU Utilization (%)]
       ,y.SystemIdle                                         AS [System Idle Process (%)]
       ,100 - y.SystemIdle - y.SQLProcessUtilization         AS [Other Process CPU Utilization (%)]
       ,DATEADD(ms, -1 * (@ts_now - y.timestamp), GETDATE()) AS [Event Time]
FROM    (
            SELECT  x.record.value('(./Record/@id)[1]', 'int') AS record_id
                   ,x.record.value(
                                      '(./Record/SchedulerMonitorEvent/
                                     SystemHealth/SystemIdle)[1]', 'int'
                                  )                            AS SystemIdle
                   ,x.record.value(
                                      '(./Record/SchedulerMonitorEvent/
                                     SystemHealth/ProcessUtilization)[1]', 'int'
                                  )                            AS SQLProcessUtilization
                   ,x.timestamp
            FROM    (
                        SELECT  timestamp
                               ,CONVERT(XML, record) AS record
                        FROM    sys.dm_os_ring_buffers
                        WHERE   ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
                        AND     record LIKE N'%<SystemHealth>%'
                    ) AS x
        ) AS y
ORDER BY y.record_id DESC;


--You can also monitor the SQL Server schedulers using the sys.dm_os_schedulers view to see if the number of runnable tasks
--is typically nonzero. A nonzero value indicates that tasks have to wait for their time slice to run; high values for this
--counter are a symptom of a CPU bottleneck. You can use the following query to list all the schedulers and look at the
--number of runnable tasks.
SELECT  scheduler_id
       ,current_tasks_count
       ,runnable_tasks_count
FROM    sys.dm_os_schedulers
WHERE   scheduler_id < 255
AND     runnable_tasks_count > 0;


--The following query gives you a high-level view of which currently cached batches or procedures are using the most CPU. The
--query aggregates the CPU consumed by all statements with the same plan__handle (meaning that they are part of the same batch
--or procedure). If a given plan_handle has more than one statement, you may have to drill in further to find the specific query
--that is the largest contributor to the overall CPU usage.
SELECT  TOP (50)
        SUM(qs.total_worker_time)                           AS total_cpu_time
       ,SUM(qs.execution_count)                             AS total_execution_count
       ,COUNT(*)                                            AS number_of_statements
       ,SUM(qs.total_worker_time) / SUM(qs.execution_count) AS avg_cpu_time_per_exec
       ,qs.plan_handle
FROM    sys.dm_exec_query_stats qs
GROUP BY qs.plan_handle
ORDER BY SUM(qs.total_worker_time) DESC;


--SELECT * FROM sys.dm_exec_query_plan ( 0x05000F00B987BE0DA035DDFE0300000001000000000000000000000000000000000000000000000000000000 )
--SELECT OBJECT_NAME(644197345)



/*
SQL SERVER – List Number Queries Waiting for Memory Grant Pending
https://blog.sqlauthority.com/2019/12/10/sql-server-list-number-queries-waiting-for-memory-grant-pending/

Poison Wait Detected: RESOURCE_SEMAPHORE
https://social.msdn.microsoft.com/Forums/SqlServer/en-US/61352bc0-8f8f-4e41-8121-4f6d16fdc0f2/poison-wait-detected-resourcesemaphore?forum=sqldatabaseengine
*/

-- OS MEMORY AND STATE
-- state = 'Available physical memory is high' indicates not under external memory pressure
SELECT	(total_physical_memory_kb/1024/1024) total_physical_memory_GB			-- Total size of physical memory available to the operating system, in KB
		,(available_physical_memory_kb/1024/1024) available_physical_memory_GB	-- Size of physical memory available, in KB
		,(total_page_file_kb/1024/1024)	total_page_file_GB						-- Size of the commit limit reported by the operating system, in KB
		,(available_page_file_kb/1024/1024) available_page_file_GB				-- Total amount of page file that is not being used, in KB
		,system_memory_state_desc												-- Description of the memory state
FROM	sys.dm_os_sys_memory WITH (NOLOCK) OPTION (RECOMPILE);

-- MEMORY ALLOCATED TO SQL SERVER
--(shows whether locked pages is enabled, among other things)
-- process_physical_memory_low = 0 AND process_virtual_memory_low = 0 indicates not under internal memory pressure
SELECT	(physical_memory_in_use_kb/1024/1024) physical_memory_in_use_GB			-- Working set, in KB, as reported by OS
		,(locked_page_allocations_kb/1024/1024) locked_page_allocations_GB		-- Memory pages locked in memory
		,page_fault_count														-- Number of page faults incurred by SQL Server process
		,memory_utilization_percentage											-- Percentage of committed memory that is in the working set
		,(available_commit_limit_kb/1024/1024) available_commit_limit_GB		-- Amount of memory available to be committed by the process
		,process_physical_memory_low											-- Indicates process is responding to low physical memory notification
		,process_virtual_memory_low												-- Indicates low virtual memory condition has been detected
FROM	sys.dm_os_process_memory WITH (NOLOCK) OPTION (RECOMPILE);

-- HOW MANY QUERIES ARE WAITING FOR A MEMORY GRANT
SELECT	@@SERVERNAME AS [Server Name]
		,[cntr_value] AS [Memory Grants Pending]
FROM	sys.dm_os_performance_counters WITH (NOLOCK)
WHERE	[object_name] LIKE N'%Memory Manager%'
AND		[counter_name] = N'Memory Grants Pending';

-- ACTIVE QUERIES REQUIRING A MEMORY GRANT
SELECT	mg.session_id
		,(mg.requested_memory_kb/1024) requested_memory_MB	-- Total requested amount of memory, in KB
		,(mg.granted_memory_kb/1024) granted_memory_MB		-- Total amount of memory granted, in KB
		,(mg.required_memory_kb/1024) required_memory_MB	-- Minimum memory required to run this query, in KB
		,(mg.used_memory_kb/1024) used_memory_MB			-- Physical memory used at this moment, in KB
		,(mg.ideal_memory_kb/1024) ideal_memory_MB			-- Size, in KB, of memory grant to fit everything into physical memory (based on cardinality estimate)
		,mg.request_time									-- Date and time when this query requested the memory grant
		,mg.grant_time										-- Date and time when memory was granted for this query (NULL if memory is not granted yet)
		,mg.query_cost										-- Estimated query cost
		,mg.dop												-- Degree of parallelism of this query
		,mg.wait_order
		,DB_NAME(s.database_id) as [database]
		,st.[TEXT] AS query_text
		,s.login_name
		,s.host_name
		,s.program_name
		,qp.query_plan
FROM	sys.dm_exec_query_memory_grants AS mg
		CROSS APPLY sys.dm_exec_sql_text(mg.plan_handle) AS st
		CROSS APPLY sys.dm_exec_query_plan(mg.plan_handle) AS qp
		JOIN sys.dm_exec_sessions AS s ON mg.session_id = s.session_id
ORDER BY mg.granted_memory_kb DESC
		,mg.grant_time
		,mg.wait_order;


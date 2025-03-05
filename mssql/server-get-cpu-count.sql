
SELECT	NUMA_nodes = COUNT(DISTINCT memory_node_id)
FROM	sys.dm_os_memory_clerks
WHERE	memory_node_id != 64;

SELECT	cpu_count
FROM	sys.dm_os_sys_info;

SELECT	NUMA_node = parent_node_id
		, scheduler_id
		, cpu_id
		, is_online
FROM	sys.dm_os_schedulers
WHERE	[status] = 'VISIBLE ONLINE';


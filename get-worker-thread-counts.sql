
select	(select max_workers_count from sys.dm_os_sys_info) as 'TotalThreads'
		,sum(active_Workers_count) as 'Currentthreads'
		,(select max_workers_count from sys.dm_os_sys_info)-sum(active_Workers_count) as 'Availablethreads'
		,sum(runnable_tasks_count) as 'WorkersWaitingfor_cpu'
		,sum(work_queue_count) as 'Request_Waiting_for_threads' 
from	sys.dm_os_Schedulers
where	status='VISIBLE ONLINE'

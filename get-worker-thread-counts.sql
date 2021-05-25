
select	(select max_workers_count from sys.dm_os_sys_info) as 'TotalThreads'
		,sum(active_Workers_count) as 'Currentthreads'
		,(select max_workers_count from sys.dm_os_sys_info)-sum(active_Workers_count) as 'Availablethreads'
		,sum(runnable_tasks_count) as 'WorkersWaitingfor_cpu'
		,sum(work_queue_count) as 'Request_Waiting_for_threads' 
from	sys.dm_os_Schedulers
where	status='VISIBLE ONLINE'


SELECT  s.session_id, r.command, r.status,  
   r.wait_type, r.scheduler_id, w.worker_address,  
   w.is_preemptive, w.state, t.task_state,  
   t.session_id, t.exec_context_id, t.request_id  
FROM sys.dm_exec_sessions AS s  
INNER JOIN sys.dm_exec_requests AS r  
   ON s.session_id = r.session_id  
INNER JOIN sys.dm_os_tasks AS t  
   ON r.task_address = t.task_address  
INNER JOIN sys.dm_os_workers AS w  
   ON t.worker_address = w.worker_address  
WHERE s.is_user_process = 0;  
DECLARE @session_id INT = 411;

SELECT  wt.session_id, 
    ot.task_state, 
    wt.wait_type, 
    wt.wait_duration_ms, 
    wt.blocking_session_id, 
    wt.resource_description, 
    es.[host_name], 
    es.[program_name] 
FROM  sys.dm_os_waiting_tasks  wt  
INNER  JOIN sys.dm_os_tasks ot ON ot.task_address = wt.waiting_task_address 
INNER JOIN sys.dm_exec_sessions es ON es.session_id = wt.session_id 
WHERE es.is_user_process =  1 
and  wt.session_id = @session_id;
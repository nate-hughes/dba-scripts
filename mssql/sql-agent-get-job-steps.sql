
SELECT @@SERVERNAME AS servername 
	,j.name AS jobname 
	,js.step_id 
	,js.step_name 
	,js.subsystem 
	,js.command 
	,js.on_success_action 
	,js.on_success_step_id 
	,js.on_fail_action 
	,js.on_fail_step_id 
	,js.database_name 
	,js.database_user_name 
	,js.retry_attempts 
	,js.retry_interval 
	,js.output_file_name
	,CASE WHEN j.start_step_id = js.step_id THEN 1 ELSE 0 END AS start_step_id
FROM msdb..sysjobs j
	INNER JOIN msdb..sysjobsteps js ON j.job_id = js.job_id;


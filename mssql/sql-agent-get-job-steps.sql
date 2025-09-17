DECLARE @enabled TINYINT = 1 -- use NULL to return ALL jobs

SELECT @@SERVERNAME AS servername 
	,j.name AS jobname 
	,jo.name AS jobowner
	,js.step_id 
	,js.step_name 
	,js.subsystem 
	,js.command 
	,js.on_success_action 
	,js.on_success_step_id 
	,js.on_fail_action 
	,js.on_fail_step_id 
	,js.database_name 
	,COALESCE(js.database_user_name,jo.name) AS run_as
	,js.retry_attempts 
	,js.retry_interval 
	,js.output_file_name
	,CASE WHEN j.start_step_id = js.step_id THEN 1 ELSE 0 END AS start_step_id
FROM msdb..sysjobs j
	INNER JOIN master.sys.server_principals jo ON j.owner_sid = jo.sid
	INNER JOIN msdb..sysjobsteps js ON j.job_id = js.job_id
WHERE (j.enabled = @enabled OR @enabled IS NULL)
ORDER BY j.name
		,js.step_id;


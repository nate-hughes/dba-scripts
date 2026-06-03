SELECT jobid, jobname, schedule, command, database, username, active
FROM cron.job;

SELECT jobid
	,status
	,to_char(start_time, 'YYYY-MM-DD HH24:MI:SS') AS start_time
	,to_char(end_time,   'YYYY-MM-DD HH24:MI:SS') AS end_time
	,to_char((end_time - start_time), 'HH24:MI:SS') AS run_time
	,database
	,return_message
	,command
FROM cron.job_run_details
ORDER BY to_char(start_time, 'YYYY-MM-DD HH24:MI:SS') desc, jobid
LIMIT 100;

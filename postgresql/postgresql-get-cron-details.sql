SELECT * FROM cron.job;

SELECT command
	,extract(epoch from (end_time::timestamp - start_time::timestamp)) / 60 as runtime_minutes
FROM cron.job_run_details
WHERE jobid = 362
ORDER BY start_time desc;

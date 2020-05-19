
DECLARE @ClusterName VARCHAR(128);

SELECT	@ClusterName = cluster_name
FROM	master.sys.dm_hadr_cluster
WHERE	LEFT(cluster_name, 1) LIKE '[a-z]';

SELECT	@ClusterName AS clustername
		,@@SERVERNAME AS servername
		,DEFAULT_DOMAIN() as domain
		,j.name AS jobname
		,s.last_run_outcome
		,h.step_id
		,h.step_name
		,h.run_status
		,h.message AS err_msg
		,((SUBSTRING(CAST(h.run_date AS VARCHAR(8)), 5, 2) + '/'
			+ SUBSTRING(CAST(h.run_date AS VARCHAR(8)), 7, 2) + '/'
			+ SUBSTRING(CAST(h.run_date AS VARCHAR(8)), 1, 4) + ' '
			+ SUBSTRING((REPLICATE('0',6-LEN(CAST(h.run_time AS varchar)))
			+ CAST(h.run_time AS VARCHAR)), 1, 2) + ':'
			+ SUBSTRING((REPLICATE('0',6-LEN(CAST(h.run_time AS VARCHAR)))
			+ CAST(h.run_time AS VARCHAR)), 3, 2) + ':'
			+ SUBSTRING((REPLICATE('0',6-LEN(CAST(h.run_time as varchar)))
			+ CAST(h.run_time AS VARCHAR)), 5, 2))) AS exec_date
		,h.run_duration
		,s.retry_attempts AS step_retry_attempts
		,h.retries_attempted
		,s.output_file_name
		,s.on_fail_action AS step_on_fail_action
FROM	msdb..sysjobs j
		JOIN msdb..sysjobsteps s ON j.job_id = s.job_id
		JOIN msdb..sysjobhistory h ON s.job_id = h.job_id AND s.step_id = h.step_id
WHERE	h.run_status = 0;


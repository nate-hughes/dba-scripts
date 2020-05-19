
SELECT @@SERVERNAME AS servername 
	,j.name AS jobname 
	,s.name AS schedulename 
	,s.enabled 
	,s.freq_type 
	,s.freq_interval 
	,s.freq_subday_type 
	,s.freq_subday_interval 
	,s.freq_relative_interval 
	,s.freq_recurrence_factor 
	,s.active_start_date 
	,s.active_start_time 
	,s.active_end_time
FROM msdb..sysjobs j
	INNER JOIN msdb..sysjobschedules js ON j.job_id = js.job_id
	INNER JOIN msdb..sysschedules s ON js.schedule_id = s.schedule_id;

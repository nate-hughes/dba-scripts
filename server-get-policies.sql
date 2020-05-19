
SELECT	@@SERVERNAME as servername
		,p.name as policyname
		,p.date_created as policy_date_created
		,p.created_by as policy_created_by
		,p.date_modified as policy_date_modified
		,p.modified_by as policy_modified_by
		,p.execution_mode
		,s.name as schedulename
		,s.enabled as scheduleenabled
		,s.freq_type
		,s.freq_interval
		,s.freq_subday_type
		,s.freq_subday_interval
		,s.freq_relative_interval
		,s.freq_recurrence_factor
		,s.active_start_date
		,s.active_start_time
		,s.active_end_time
		,p.description
		,p.is_enabled
		,j.name as jobname
		,j.enabled as jobenabled
		,c.name as conditionname
		,c.facet
		,c.expression
		,c.date_created as condition_date_created
		,c.created_by as condition_created_by
		,c.date_modified as condition_date_modified
		,c.modified_by as condition_modified_by
FROM	msdb..syspolicy_policies p
		LEFT JOIN msdb..sysschedules s ON p.schedule_uid = s.schedule_uid
		LEFT JOIN msdb..sysjobs j ON p.job_id = j.job_id
		JOIN msdb..syspolicy_conditions c ON p.condition_id = c.condition_id
WHERE	p.is_system = 0;

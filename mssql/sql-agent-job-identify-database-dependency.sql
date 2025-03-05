DECLARE @database_name SYSNAME = '?';

SELECT	j.name as job_name
		,js.step_name
		,js.subsystem
		,js.command
FROM	msdb.dbo.sysjobsteps js
		JOIN msdb.dbo.sysjobs j ON js.job_id = j.job_id
WHERE	j.enabled = 1
AND		js.database_name = @database_name
UNION
SELECT	j.name
		,js.step_name
		,js.subsystem
		,js.command
FROM	msdb.dbo.sysjobsteps js
		JOIN msdb.dbo.sysjobs j ON js.job_id = j.job_id
WHERE	j.enabled = 1
AND		js.command LIKE '%' + @database_name + '%'
UNION
SELECT	j.name
		,js.step_name
		,js.subsystem
		,js.command
FROM	msdb.dbo.sysjobsteps js
		JOIN msdb.dbo.sysjobs j ON js.job_id = j.job_id
WHERE	j.enabled = 1
AND		(
			j.name LIKE '%' + @database_name + '%'
			OR js.step_name LIKE '%' + @database_name + '%'
		)
ORDER BY job_name;
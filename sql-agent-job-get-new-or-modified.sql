DECLARE @Date DATETIME = '2021-05-11 14:15:46.250';

-- JOBS CREATED SINCE @Date
SELECT	j.name AS JobName
		,l.name AS JobOwner
		,j.date_created
		,j.enabled
FROM	msdb.dbo.sysjobs AS J
		JOIN sys.server_principals AS L ON J.owner_sid = L.sid
WHERE	j.date_created > @Date
ORDER BY j.name;

-- JOBS MODIFIED SINCE @Date
SELECT	j.name AS JobName
		,l.name AS JobOwner
		,j.date_modified
		,j.enabled
FROM	msdb.dbo.sysjobs AS J
		JOIN sys.server_principals AS L ON J.owner_sid = L.[sid]
WHERE	j.date_modified > @Date
ORDER BY j.name;

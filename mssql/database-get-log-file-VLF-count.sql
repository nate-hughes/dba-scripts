/*
Important change to VLF creation algorithm in SQL Server 2014
https://www.sqlskills.com/blogs/paul/important-change-vlf-creation-algorithm-sql-server-2014/
*/

SELECT	[name] AS 'Database Name'
		,COUNT(l.database_id) AS 'VLF Count'
		,SUM(vlf_size_mb) AS 'VLF Size (MB)'
		,SUM(CAST(vlf_active AS INT)) AS 'Active VLF'
		,SUM(vlf_active*vlf_size_mb) AS 'Active VLF Size (MB)'
		,COUNT(l.database_id)-SUM(CAST(vlf_active AS INT)) AS 'In-active VLF'
		,SUM(vlf_size_mb)-SUM(vlf_active*vlf_size_mb) AS 'In-active VLF Size (MB)'
FROM	sys.databases s
		CROSS APPLY sys.dm_db_log_info(s.database_id) l
GROUP BY [name]
ORDER BY [name];
GO


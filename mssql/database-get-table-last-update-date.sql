DECLARE @DBName NVARCHAR(128) = N'DBName'
		,@TblName NVARCHAR(128) = N'TblName';

SELECT	sqlserver_start_time
FROM	sys.dm_os_sys_info;

SELECT	OBJECT_NAME(OBJECT_ID) AS TableName
		,last_user_update
		,*
FROM	sys.dm_db_index_usage_stats
WHERE	database_id = DB_ID(@DBName)
AND		OBJECT_ID=OBJECT_ID(@TblName);

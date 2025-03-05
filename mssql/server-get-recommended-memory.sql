USE master;
GO

IF EXISTS (
	SELECT	1 
	FROM	tempdb.sys.objects
	WHERE	[type] = 'U'
	AND		[object_id] = OBJECT_ID(N'tempdb..#DB_FILE_INFO')
)
	DROP TABLE #DB_FILE_INFO;

SET NOCOUNT ON;

CREATE TABLE #DB_FILE_INFO (Used BIGINT);

DECLARE @l_sql NVARCHAR(4000)
		,@AvailableMemory_MB INT;

SET @l_sql =
'USE [?];'
+ '
INSERT #DB_FILE_INFO (Used)
SELECT	CONVERT(BIGINT, FILEPROPERTY(f.name, ''SpaceUsed'')) * 8 / 1024 -- MB
FROM	sys.database_files f
WHERE	f.data_space_id <> 0;
';

EXEC sp_msforeachdb @l_sql;

SELECT  @AvailableMemory_MB = physical_memory_kb / 1024
FROM    master.sys.dm_os_sys_info;

SELECT	@AvailableMemory_MB / 1024 AS Actual_GB
		,FLOOR(SUM(Used) * .5 / 1024) AS Rec_Min_GB
		,FLOOR(SUM(Used) * .75 / 1024) AS Rec_Max_GB
FROM	#DB_FILE_INFO;


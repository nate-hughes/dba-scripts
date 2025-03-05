
declare @sql_used nvarchar(max) = N'USE [?]; INSERT #DbUsed (DatabaseId, Used, Name) SELECT DB_ID(), CONVERT(BIGINT, FILEPROPERTY(name, ''SpaceUsed'')) * 8 / 1024, name from sys.database_files'
		,@sql_log nvarchar(max) = N'USE [?]; INSERT #LogInfo (RecoveryUnitId, FileId, FileSize, StartOffset, FSeqNo, [Status], Parity, CreateLSN) EXEC(''DBCC LOGINFO'')'
		,@Version VARCHAR(50) = LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(128)),2);

if OBJECT_ID('tempdb..#DbUsed') is not null drop table #DbUsed;
create table #DbUsed (DatabaseId INT, Used BIGINT, name VARCHAR(128));

if OBJECT_ID('tempdb..#LogInfo') is not null drop table #LogInfo;
create table #LogInfo (DatabaseName NVARCHAR(128) default DB_NAME(), RecoveryUnitId INT, FileId INT, FileSize BIGINT, StartOffset BIGINT, FSeqNo INT, [Status] TINYINT, Parity TINYINT, CreateLSN NUMERIC(25,0));

if OBJECT_ID('tempdb..#dm_hadr_database_replica_states') is not null drop table #dm_hadr_database_replica_states;
CREATE TABLE #dm_hadr_database_replica_states (database_id INT, is_primary_replica BIT);

exec sp_msforeachdb @sql_used;
exec sp_msforeachdb @sql_log;

IF @Version > 12
	INSERT #dm_hadr_database_replica_states (database_id, is_primary_replica)
	SELECT	c.database_id
			,sys.fn_hadr_is_primary_replica (DB_Name(c.database_id)) AS is_primary_replica
	FROM	sys.availability_replicas AS b
			JOIN sys.dm_hadr_database_replica_states AS c ON b.replica_id = c.replica_id
	WHERE	b.replica_server_name = @@SERVERNAME;
ELSE
	INSERT #dm_hadr_database_replica_states (database_id, is_primary_replica)
	SELECT c.database_id
		,CASE a.role_desc
			WHEN 'PRIMARY' THEN 1
			WHEN 'SECONDARY' THEN 0
			WHEN 'RESOLVING' THEN 0
			ELSE NULL
		END AS is_primary_replica
	FROM sys.dm_hadr_availability_replica_states AS a
		JOIN sys.availability_replicas AS b ON b.replica_id = a.replica_id
		JOIN sys.dm_hadr_database_replica_states AS c ON a.replica_id = c.replica_id
	WHERE b.replica_server_name = @@SERVERNAME;

SELECT @@SERVERNAME as servername
		, DB_NAME(f.database_id) as databasename
		, UPPER(LEFT(f.physical_name, 3)) as volume
		, f.name
		, f.physical_name
		, CASE WHEN DB_NAME(f.database_id) = 'tempdb' THEN CONVERT(NVARCHAR(15), CONVERT(BIGINT, tmpdb.size) * 8 / 1024)
			ELSE CONVERT(NVARCHAR(15), CONVERT(BIGINT, f.size) * 8 / 1024)
		END as filesize_mb
		, tmp.Used
		, CASE f.max_size WHEN -1 THEN N'Unlimited' ELSE CONVERT(NVARCHAR(15), CONVERT(BIGINT, f.max_size) * 8 / 1024) END as maxfilesize_mb
		, CASE f.is_percent_growth WHEN 1 THEN NULL ELSE (f.growth * 8 / 1024) END as filegrowth_mb
		, CASE f.is_percent_growth WHEN 1 THEN f.growth ELSE NULL END as filegrowth_pct
		, li.VLFs
		, rs.is_primary_replica
		, DEFAULT_DOMAIN() as domain
FROM	sys.master_files f
		LEFT OUTER JOIN #DbUsed tmp on f.database_id = tmp.DatabaseId and f.name = tmp.name
		LEFT OUTER JOIN (select DatabaseName, COUNT(FileId) as VLFs from #LogInfo group by DatabaseName) li on DB_NAME(f.database_id) = li.DatabaseName and f.name like '%log'
		LEFT OUTER JOIN #dm_hadr_database_replica_states rs on f.database_id = rs.database_id
		LEFT OUTER JOIN tempdb.sys.database_files tmpdb ON f.name = tmpdb.name AND DB_NAME(f.database_id) = 'tempdb';

DECLARE @sql_querystore NVARCHAR(2000)
		,@IsHadrEnabled TINYINT = CONVERT(TINYINT,SERVERPROPERTY ('IsHadrEnabled'))
		,@RoleDesc NVARCHAR(60) = 'PRIMARY'
		,@Version VARCHAR(50) = LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(128)),2);

if OBJECT_ID('tempdb..#query_store') is not null drop table #query_store;
CREATE TABLE #query_store (
	databasename NVARCHAR(128) DEFAULT DB_NAME()
	,query_sql_text NVARCHAR(MAX)
	,query_sproc NVARCHAR(128)
	,query_id BIGINT
	,query_plan_hash BINARY(8)
	,query_plan XML
	,last_execution_date DATE
	,is_forced_plan BIT
	,is_natively_compiled BIT
	,force_failure_count BIGINT
	,last_force_failure_reason_desc NVARCHAR(128)
	,plan_forcing_type_desc NVARCHAR(60)
);

SET @sql_querystore = 'USE [?];
IF DB_ID() > 4
INSERT #query_store (
	query_sql_text
	,query_sproc
	,query_id
	,query_plan_hash
	,query_plan
	,last_execution_date
	,is_forced_plan
	,is_natively_compiled
	,force_failure_count
	,last_force_failure_reason_desc
	,plan_forcing_type_desc
)
SELECT qsqt.query_sql_text,
       OBJECT_NAME(qsq.object_id) AS ProcedureName,
	   qsq.query_id,
       qsp.query_plan_hash,
       CAST(qsp.query_plan AS XML) AS query_plan,
	   qsq.last_execution_time,
       qsp.is_forced_plan,
       qsp.is_natively_compiled,
       qsp.force_failure_count,
       qsp.last_force_failure_reason_desc,'
		+ CASE WHEN @Version > 13 THEN '	qsp.plan_forcing_type_desc' ELSE '	NULL' END + '
FROM sys.query_store_query qsq 
	INNER JOIN sys.query_store_query_text qsqt ON qsqt.query_text_id = qsq.query_text_id
	INNER JOIN sys.query_store_plan qsp ON qsp.query_id = qsq.query_id
WHERE qsp.is_forced_plan = 1'
	
IF @IsHadrEnabled = 0
OR (
	@IsHadrEnabled = 1
	AND EXISTS (
		SELECT 1
		FROM sys.dm_hadr_availability_replica_states AS a
			JOIN sys.availability_replicas AS b
		ON b.replica_id = a.replica_id
		WHERE b.replica_server_name = @@SERVERNAME
		AND a.role_desc = @RoleDesc
	)
)
	EXEC sp_msforeachdb @sql_querystore;

SELECT	@@SERVERNAME AS servername
		,databasename
		,query_sql_text
		,query_sproc
		,query_id
		,CONVERT(VARCHAR(48),query_plan_hash,2) AS query_plan_hash
		,query_plan
		,last_execution_date
		,is_forced_plan
		,is_natively_compiled
		,force_failure_count
		,last_force_failure_reason_desc
		,plan_forcing_type_desc
FROM	#query_store;

DROP TABLE IF EXISTS #query_store;

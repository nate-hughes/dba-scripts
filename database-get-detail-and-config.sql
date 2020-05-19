
DECLARE @tmp_ExtProperties TABLE (DatabaseName VARCHAR(128), name NVARCHAR(60), value SQL_VARIANT);

INSERT INTO @tmp_ExtProperties (DatabaseName, name, value)
EXEC sp_MSForEachDB 'Use [?];
SELECT DB_NAME() AS DatabaseName, name, value FROM sys.extended_properties WHERE name = ''Confluence Description''';

DECLARE @tmp_FileStream TABLE (DatabaseName VARCHAR(128), non_transacted_access TINYINT, directory_name NVARCHAR(255));

INSERT @tmp_FileStream (DatabaseName, non_transacted_access, directory_name)
EXEC sp_MSForEachDB 'Use [?];
SELECT DB_NAME() AS DatabaseName, non_transacted_access, directory_name FROM sys.database_filestream_options';

DECLARE @tmp_QueryStore TABLE (
	DatabaseName VARCHAR(128)
	,querystore_desired_state SMALLINT
	,querystore_actual_state SMALLINT
	,querystore_readonly_reason INT
	,querystore_current_storage_size_mb BIGINT
	,querystore_flush_interval_seconds BIGINT
	,querystore_interval_length_minutes BIGINT
	,querystore_max_storage_size_mb BIGINT
	,querystore_stale_query_threshold_days BIGINT
	,querystore_max_plans_per_query BIGINT
	,querystore_query_capture_mode SMALLINT
	,querystore_size_based_cleanup_mode SMALLINT
	,querystore_wait_stats_capture_mode SMALLINT
);

DECLARE @QS_SQL NVARCHAR(MAX)
		,@Version VARCHAR(50) = LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(128)),2);

IF @Version > 12
BEGIN
SET @QS_SQL = 'Use [?];
SELECT DB_NAME() AS DatabaseName
	,desired_state
	,actual_state
	,readonly_reason
	,current_storage_size_mb
	,flush_interval_seconds
	,interval_length_minutes
	,max_storage_size_mb
	,stale_query_threshold_days
	,max_plans_per_query
	,query_capture_mode
	,size_based_cleanup_mode'
+ CASE WHEN @Version > 13 THEN '	,wait_stats_capture_mode' ELSE '	,NULL' END + '
FROM sys.database_query_store_options';

INSERT @tmp_QueryStore (
	DatabaseName
	,querystore_desired_state
	,querystore_actual_state
	,querystore_readonly_reason
	,querystore_current_storage_size_mb
	,querystore_flush_interval_seconds
	,querystore_interval_length_minutes
	,querystore_max_storage_size_mb
	,querystore_stale_query_threshold_days
	,querystore_max_plans_per_query
	,querystore_query_capture_mode
	,querystore_size_based_cleanup_mode
	,querystore_wait_stats_capture_mode
)
EXEC sp_MSForEachDB @QS_SQL;
END;

SELECT *
INTO #databases
FROM sys.databases;

IF @Version < 12
BEGIN
	ALTER TABLE #databases ADD
		is_auto_create_stats_incremental_on BIT
		,delayed_durability INT
		,is_query_store_on BIT;
END;

IF @Version < 13
BEGIN
	ALTER TABLE #databases ADD
		is_mixed_page_allocation_on BIT;;
END;

CREATE TABLE #dm_hadr_database_replica_states (
	database_id INT
	,group_id UNIQUEIDENTIFIER
	,is_primary_replica BIT
);

IF @Version > 12
	INSERT #dm_hadr_database_replica_states (database_id, group_id, is_primary_replica)
	SELECT	c.database_id
			,b.group_id
			,sys.fn_hadr_is_primary_replica (DB_Name(c.database_id)) AS is_primary_replica
	FROM	sys.availability_replicas AS b
			JOIN sys.dm_hadr_database_replica_states AS c ON b.replica_id = c.replica_id
	WHERE	b.replica_server_name = @@SERVERNAME;
ELSE
	INSERT #dm_hadr_database_replica_states (database_id, group_id, is_primary_replica)
	SELECT c.database_id, a.group_id
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

SELECT ag_id, ag_name
INTO #dm_hadr_name_id_map
FROM sys.dm_hadr_name_id_map;

SELECT sid, name
INTO #server_principals
FROM sys.server_principals;

select distinct
	@@SERVERNAME as servername
	,sd.name as databasename
	,grp.ag_name as agname
	,hdrs.is_primary_replica
	,ep.value as description
	,ISNULL(u.name, '') as databaseowner
	,sd.collation_name as collation
	,sd.recovery_model_desc as recoverymodel
	,sd.compatibility_level as compatibilitylevel
	,sd.containment_desc as containmenttype
	,sd.is_auto_close_on
	,sd.is_auto_create_stats_incremental_on
	,sd.is_auto_create_stats_on
	,sd.is_auto_shrink_on
	,sd.is_auto_update_stats_on
	,sd.is_auto_update_stats_async_on
	,sd.is_cursor_close_on_commit_on
	,sd.is_local_cursor_default
	,sd.snapshot_isolation_state
	,sd.is_ansi_null_default_on
	,sd.is_ansi_nulls_on
	,sd.is_ansi_padding_on
	,sd.is_ansi_warnings_on
	,sd.is_arithabort_on
	,sd.is_concat_null_yields_null_on
	,sd.is_db_chaining_on
	,sd.is_date_correlation_on
	,sd.delayed_durability
	,sd.is_mixed_page_allocation_on
	,sd.is_read_committed_snapshot_on
	,sd.is_numeric_roundabort_on
	,sd.is_parameterization_forced
	,sd.is_quoted_identifier_on
	,sd.is_recursive_triggers_on
	,sd.is_nested_triggers_on
	,sd.is_trustworthy_on
	,sd.page_verify_option
	,sd.target_recovery_time_in_seconds
	,sd.is_broker_enabled
	,sd.is_honor_broker_priority_on
	,sd.service_broker_guid
	,sd.is_read_only
	,sd.state
	,sd.is_in_standby
	,sd.is_encrypted
	,sd.is_master_key_encrypted_by_server
	,sd.user_access
	,sd.is_cdc_enabled
	,sd.is_fulltext_enabled
	,fs.non_transacted_access
	,fs.directory_name
	,sd.is_query_store_on
	,qs.querystore_desired_state
	,qs.querystore_actual_state
	,qs.querystore_readonly_reason
	,qs.querystore_current_storage_size_mb
	,qs.querystore_flush_interval_seconds
	,qs.querystore_interval_length_minutes
	,qs.querystore_max_storage_size_mb
	,qs.querystore_stale_query_threshold_days
	,qs.querystore_max_plans_per_query
	,qs.querystore_query_capture_mode
	,qs.querystore_size_based_cleanup_mode
	,qs.querystore_wait_stats_capture_mode
from #databases as sd
    left outer join #dm_hadr_database_replica_states as hdrs on hdrs.database_id = sd.database_id
    left outer join #dm_hadr_name_id_map as grp on grp.ag_id = hdrs.group_id
    left outer join @tmp_ExtProperties ep on ep.DatabaseName = sd.name
	left outer join #server_principals u on sd.owner_sid = u.sid
	left outer join @tmp_FileStream fs on fs.DatabaseName = sd.name
	left outer join @tmp_QueryStore qs on qs.DatabaseName = sd.name
where sd.name not in ('master','msdb','model','tempdb', 'ReportServer', 'ReportServerTempDB');

IF OBJECT_ID('tempdb..#databases') IS NOT NULL
 DROP TABLE #databases;

IF OBJECT_ID('tempdb..#dm_hadr_database_replica_states') IS NOT NULL
 DROP TABLE #dm_hadr_database_replica_states;
 
IF OBJECT_ID('tempdb..#dm_hadr_name_id_map') IS NOT NULL
 DROP TABLE #dm_hadr_name_id_map;

IF OBJECT_ID('tempdb..#server_principals') IS NOT NULL
 DROP TABLE #server_principals;

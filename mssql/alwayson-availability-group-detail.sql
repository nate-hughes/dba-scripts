
-- RUN ON PRIMARY --

DECLARE @IsHadrEnabled TINYINT = CONVERT(TINYINT,SERVERPROPERTY ('IsHadrEnabled'))
		,@ServerName NVARCHAR(256) = @@SERVERNAME 
		,@RoleDesc NVARCHAR(60) = 'PRIMARY'
		,@AG_SQL NVARCHAR(MAX)
		,@Version VARCHAR(50) = LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(128)),2);

DECLARE @AGs TABLE (
	domain VARCHAR(128) NOT NULL
	,primaryreplicaservername VARCHAR(128) NOT NULL
	,availabilitygroupname VARCHAR(128) NOT NULL
	,failure_condition_level INT NOT NULL
	,health_check_timeout INT NOT NULL
	,automated_backup_preference TINYINT NOT NULL
	,listener_name VARCHAR(63) NULL
	,listener_port INT NULL
	,listener_ip VARCHAR(200) NULL
	,dtc_support BIT NULL
	,db_failover BIT NULL
);

IF (@IsHadrEnabled = 1)
AND EXISTS (
	SELECT 1
	FROM sys.dm_hadr_availability_replica_states AS a
		JOIN sys.availability_replicas AS b
	ON b.replica_id = a.replica_id
	WHERE b.replica_server_name = @ServerName
	AND	a.role_desc = @RoleDesc
)
BEGIN
	SELECT *
	INTO #availability_groups
	FROM sys.availability_groups;

	SELECT group_id, dns_name, port, ip_configuration_string_from_cluster
	INTO #availability_group_listeners
	FROM sys.availability_group_listeners;

	SET @AG_SQL = '
	SELECT	DEFAULT_DOMAIN() as domain
			,''' + @ServerName + ''' as primaryreplicaservername
			,ag.name
			,ag.failure_condition_level
			,ag.health_check_timeout
			,ag.automated_backup_preference
			,l.dns_name
			,l.port
			,l.ip_configuration_string_from_cluster'
	+ CASE WHEN @Version > 11 THEN '	,ag.dtc_support' ELSE '	,NULL' END
	+ CASE WHEN @Version > 11 THEN '	,ag.db_failover' ELSE '	,NULL' END + '
	FROM	#availability_groups ag
			JOIN #availability_group_listeners l ON ag.group_id = l.group_id'

	INSERT @AGs (
		domain
		,primaryreplicaservername
		,availabilitygroupname
		,failure_condition_level
		,health_check_timeout
		,automated_backup_preference
		,listener_name
		,listener_port
		,listener_ip
		,dtc_support
		,db_failover
	)
	EXEC sp_executesql @AG_SQL;
END;

SELECT * FROM @AGs;

IF OBJECT_ID('tempdb..#availability_groups') IS NOT NULL
 DROP TABLE #availability_groups;

IF OBJECT_ID('tempdb..#availability_group_listeners') IS NOT NULL
 DROP TABLE #availability_group_listeners;

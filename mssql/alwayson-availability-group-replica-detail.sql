
-- RUN ON PRIMARY --

DECLARE @IsHadrEnabled TINYINT = CONVERT(TINYINT,SERVERPROPERTY ('IsHadrEnabled'))
		,@ServerName NVARCHAR(256) = @@SERVERNAME 
		,@RoleDesc NVARCHAR(60) = 'PRIMARY'
		,@AG_SQL NVARCHAR(MAX)
		,@Version VARCHAR(50) = LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(128)),2);

DECLARE @AGs TABLE (
	domain VARCHAR(128) NOT NULL
	,availabilitygroupname VARCHAR(128) NOT NULL
	,replicaservername VARCHAR(128) NOT NULL
	,endpoint_url VARCHAR(128) NULL
	,availability_mode TINYINT NOT NULL
	,failover_mode TINYINT NOT NULL
	,session_timeout INT NOT NULL
	,primary_role_allow_connections TINYINT NOT NULL
	,secondary_role_allow_connections TINYINT NOT NULL
	,backup_priority INT NOT NULL
	,read_only_routing_url VARCHAR(256) NULL
	,seeding_mode TINYINT NULL
	,read_only_routing_lists VARCHAR(1000) NULL
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
	INTO #availability_read_only_routing_lists
	FROM sys.availability_read_only_routing_lists;

	SELECT *
	INTO #availability_replicas
	FROM sys.availability_replicas;
	
	SELECT group_id, name
	INTO #availability_groups
	FROM sys.availability_groups;

	SET @AG_SQL = '
	WITH read_only_routing_lists AS (
	
		SELECT	r.replica_id
				,STUFF((
					SELECT '','' + ror.replica_server_name
					FROM #availability_read_only_routing_lists l
						JOIN #availability_replicas ror ON l.read_only_replica_id = ror.replica_id
					WHERE r.replica_id = l.replica_id
					ORDER BY l.routing_priority
					FOR XML PATH(''''),TYPE).value(''.'',''VARCHAR(MAX)''),1,1,'''') AS read_only_replicas
		FROM	#availability_replicas r
	)

SELECT	DEFAULT_DOMAIN() as domain
		,ag.name
		,r.replica_server_name
		,r.endpoint_url
		,r.availability_mode
		,r.failover_mode
		,r.session_timeout
		,r.primary_role_allow_connections
		,r.secondary_role_allow_connections
		,r.backup_priority
		,r.read_only_routing_url'
		+ CASE WHEN @Version > 11 THEN '	,r.seeding_mode' ELSE '	,NULL' END + '
		,ro.read_only_replicas
FROM	#availability_groups ag
		JOIN #availability_replicas r on ag.group_id = r.group_id
		LEFT JOIN read_only_routing_lists ro ON r.replica_id = ro.replica_id'

	INSERT @AGs (
		domain
		,availabilitygroupname
		,replicaservername
		,endpoint_url
		,availability_mode
		,failover_mode
		,session_timeout
		,primary_role_allow_connections
		,secondary_role_allow_connections
		,backup_priority
		,read_only_routing_url
		,seeding_mode
		,read_only_routing_lists
	)
	EXEC sp_executesql @AG_SQL;
END;

SELECT * FROM @AGs;

IF OBJECT_ID('tempdb..#availability_read_only_routing_lists') IS NOT NULL
 DROP TABLE #availability_read_only_routing_lists;

IF OBJECT_ID('tempdb..#availability_replicas') IS NOT NULL
 DROP TABLE #availability_replicas;
 
IF OBJECT_ID('tempdb..#availability_groups') IS NOT NULL
 DROP TABLE #availability_groups;

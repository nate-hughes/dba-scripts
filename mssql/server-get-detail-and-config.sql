
DECLARE @ProductVersion VARCHAR(50) = CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(128))
		,@Version VARCHAR(50) = LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(128)),2)
		,@sql_memory_model_desc VARCHAR(120)
		,@affinity_type_desc VARCHAR(60)
		,@BiosReleaseDate DATE
		,@ProcessorNameString VARCHAR(255);
		
EXEC master.sys.xp_instance_regread
	@rootkey=N'HKEY_LOCAL_MACHINE'
	,@key=N'HARDWARE\DESCRIPTION\System\BIOS'
	,@value_name=N'BiosReleaseDate'
    ,@value=@BiosReleaseDate OUTPUT;
	
EXEC master.sys.xp_instance_regread
	@rootkey=N'HKEY_LOCAL_MACHINE'
	,@key=N'HARDWARE\DESCRIPTION\System\CentralProcessor\0'
	,@value_name=N'ProcessorNameString'
    ,@value=@ProcessorNameString OUTPUT;

IF @Version >= 11
	SELECT	@sql_memory_model_desc = sql_memory_model_desc
			,@affinity_type_desc = affinity_type_desc
	FROM	sys.dm_os_sys_info;

CREATE TABLE #os_sys_info_adds (
	socket_count INT
	,cores_per_socket INT
	,numa_node_count INT
	,softnuma_configuration_desc VARCHAR(60)
);

IF @Version >= 13
	INSERT #os_sys_info_adds (socket_count, cores_per_socket, numa_node_count, softnuma_configuration_desc)
	SELECT	socket_count
			,cores_per_socket
			,numa_node_count
			,softnuma_configuration_desc
	FROM	sys.dm_os_sys_info;

CREATE TABLE #os_windows_info (
	windows_release VARCHAR(256)
	,windows_service_pack_level VARCHAR(256)
	,host_platform VARCHAR(256)
	,host_distribution VARCHAR(256)
);

IF @Version >= 14
	INSERT #os_windows_info (windows_release, windows_service_pack_level, host_platform, host_distribution)
	SELECT	host_release
			,host_service_pack_level
			,host_platform
			,host_distribution
	FROM sys.dm_os_host_info
ELSE
	INSERT #os_windows_info (windows_release, windows_service_pack_level)
	SELECT	windows_release
			, REPLACE(windows_service_pack_level,'Service Pack ','')
	FROM	sys.dm_os_windows_info

SELECT	SERVERPROPERTY('ServerName') AS HostName -- Both the Windows server and instance information associated with a specified instance of SQL Server.
		,SERVERPROPERTY('MachineName') AS MachineName -- For a clustered instance, Windows computer name on which the server instance is running.
		,DEFAULT_DOMAIN() AS Domain
		,ec.local_net_address AS IP
		,ec.local_tcp_port AS Port
		--,SERVERPROPERTY('Edition') AS Product -- Installed product edition of the instance of SQL Server.
		,CASE WHEN @ProductVersion LIKE '8.%' THEN '2000'
			WHEN @ProductVersion LIKE '9.%' THEN '2005'
			WHEN @ProductVersion LIKE '10.0%' THEN '2008'
			WHEN @ProductVersion LIKE '10.5%' THEN '2008 R2'
			WHEN @ProductVersion LIKE '11.%' THEN '2012'
			WHEN @ProductVersion LIKE '12.%' THEN '2014'
			WHEN @ProductVersion LIKE '13.%' THEN '2016'
			WHEN @ProductVersion LIKE '14.%' THEN '2017'
			WHEN @ProductVersion LIKE '15.%' THEN '2019'
		END + ' ' + 
		CASE CAST(SERVERPROPERTY('EngineEdition') AS NVARCHAR(128))
			WHEN '2' THEN 'Std'
			WHEN '3' THEN 'Ent'
			WHEN '4' THEN 'Exp'
		END  +
		CASE WHEN CAST(SERVERPROPERTY('Edition') AS NVARCHAR(128)) LIKE '%64%' THEN ' x64'
			ELSE ' x32'
		END
		AS Product
		,SERVERPROPERTY('ProductLevel') AS SP -- Level of the version of the instance of SQL Server.
		,@ProductVersion AS Version -- Version of the instance of SQL Server, in the form of 'major.minor.build.revision'.
		,ISNULL(SERVERPROPERTY('ProductUpdateLevel'),'') AS CU -- Update level of the current build.
		,CASE WHEN SERVERPROPERTY('IsClustered') = 1 THEN 'Y' ELSE 'N' END AS IsClustered -- Server instance is configured in a failover cluster.
		,CASE WHEN SERVERPROPERTY('IsFullTextInstalled') = 1 THEN 'Y' ELSE 'N' END AS IsFullTextInstalled -- Full-text and semantic indexing components are installed.
		,CASE WHEN SERVERPROPERTY('IsHadrEnabled') = 1 THEN 'Y' ELSE 'N' END AS IsHadrEnabled -- Always On Availability Groups is enabled on this server instance.
		,CAST(ROUND(os.physical_memory_kb / 1024.0 / 1024.0,0) AS INT) AS MemoryGB -- Specifies the total amount of physical memory on the machine. Not nullable. Converted to GB.
		,@sql_memory_model_desc AS MemoryModel
		,mn.memory_nodes AS MemoryNodes
		,@ProcessorNameString AS Processor
		,os.cpu_count AS LogicalCPU
		,tmp_add.socket_count AS SocketCount
		,tmp_add.cores_per_socket AS CoresPerSocket
		,tmp_add.numa_node_count AS NUMANodeCount
		,os.max_workers_count AS MaxWorkersCount
		,@affinity_type_desc AS AffinityType
		,tmp_add.softnuma_configuration_desc AS SoftNUMAConfiguration
		,COALESCE(wi.host_platform
			,CASE WHEN wi.windows_release = '6.1' THEN 'Windows Server 2008 R2'
				WHEN wi.windows_release = '6.2' THEN 'windows Server 2012'
				WHEN wi.windows_release = '6.3' THEN 'windows Server 2012 R2'
				WHEN wi.windows_release = '10.0' THEN 'Windows Server 2016'
				ELSE 'UNKNOWN'
			END -- https://msdn.microsoft.com/library/ms724832%28vs.85%29.aspx?f=255&MSPPError=-2147217396
		) AS OS
		,wi.host_distribution AS OSDescription
		,wi.windows_release AS OSVersion -- For Windows, returns the release number. Cannot be NULL.
		,wi.windows_service_pack_level AS OSServicePack -- For Windows, returns the service pack number. Cannot be NULL.
		,@BiosReleaseDate AS BiosDate
FROM	sys.dm_os_sys_info os
		CROSS JOIN #os_windows_info wi
		CROSS JOIN sys.dm_exec_connections ec
		CROSS JOIN (select COUNT(*) as memory_nodes from sys.dm_os_memory_nodes where memory_node_id <> 64) mn
		CROSS JOIN #os_sys_info_adds tmp_add
WHERE	ec.session_id = @@SPID;

DROP TABLE IF EXISTS #os_sys_info_adds;
DROP TABLE IF EXISTS #os_windows_info;

DECLARE @LoginAuditing INT
		,@DefaultData NVARCHAR(512)
		,@DefaultLog NVARCHAR(512)
		,@DefaultBackup NVARCHAR(512)
		,@NUMANodes INT
		,@TempDbFiles INT
		,@RegKey VARCHAR(100)
		,@SQLVersion VARCHAR(10)
		,@FailSafeOperator VARCHAR(50)
		,@DatabaseMailProfile VARCHAR(50);

EXEC master..xp_instance_regread 
    @rootkey='HKEY_LOCAL_MACHINE',
    @key='SOFTWARE\Microsoft\MSSQLServer\MSSQLServer',
    @value_name='AuditLevel',
    @value=@LoginAuditing OUTPUT;
	
IF @Version >= 11
BEGIN
	SET @DefaultData = CAST(SERVERPROPERTY('InstanceDefaultDataPath') AS VARCHAR(128));
	SET @DefaultLog = CAST(SERVERPROPERTY('InstanceDefaultLogPath') AS VARCHAR(128));
END;
ELSE
BEGIN
	EXEC master.dbo.xp_instance_regread 
		@rootkey='HKEY_LOCAL_MACHINE',
		@key='SOFTWARE\Microsoft\MSSQLServer\MSSQLServer',
		@value_name='DefaultData',
		@value=@DefaultData OUTPUT;

	EXEC master.dbo.xp_instance_regread 
		@rootkey='HKEY_LOCAL_MACHINE',
		@key='SOFTWARE\Microsoft\MSSQLServer\MSSQLServer',
		@value_name='DefaultLog',
		@value=@DefaultLog OUTPUT;
END;

EXEC master.dbo.xp_instance_regread 
    @rootkey='HKEY_LOCAL_MACHINE',
    @key='SOFTWARE\Microsoft\MSSQLServer\MSSQLServer',
    @value_name='BackupDirectory',
    @value=@DefaultBackup OUTPUT;
	
SELECT @SQLVersion = LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(128)),2)
SET @RegKey = REPLACE('SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL00.MSSQLSERVER\SQLServerAgent', '00', @SQLVersion);
EXECUTE master.sys.xp_regread 'HKEY_LOCAL_MACHINE', @RegKey, 'AlertFailSafeOperator', @FailSafeOperator output;
EXECUTE master.sys.xp_regread 'HKEY_LOCAL_MACHINE', @RegKey, 'DatabaseMailProfile', @DatabaseMailProfile output;

/*
http://www.sqlpassion.at/archive/2016/10/17/how-many-numa-nodes-do-i-have/
For every available NUMA node SQL Server creates one dedicated Memory Node (besides Memory Node ID 64, which is always
present for the Dedicated Admin Connection).
*/

SELECT	@TempDbFiles = COUNT(*)
FROM	tempdb.sys.database_files
WHERE	type = 0;

SELECT	CAST(ROUND(MAX(os.physical_memory_kb) / 1024.0 / 1024.0,0) AS INT) AS HostMemory_GB
		,CAST(MAX(CASE WHEN config.name = 'min server memory (MB)' THEN config.value END) AS INT) / 1024 AS MinMemory_GB
		,CAST(MAX(CASE WHEN config.name = 'max server memory (MB)' THEN config.value END) AS INT) / 1024 AS MaxMemory_GB
		,MAX(CASE WHEN SERVERPROPERTY('IsIntegratedSecurityOnly') = 0 THEN 'Y' ELSE 'N' END) AS MixedMode
		,MAX(CASE @LoginAuditing
				WHEN 0 THEN 'None'
				WHEN 1 THEN 'Successful Logins Only'
				WHEN 2 THEN 'Failed Logins Only'
				WHEN 3 THEN 'Both Failed and Successful Logins'
		END) AS LoginAuditing
		,MAX(CASE WHEN config.name = 'cross db ownership chaining' AND config.value = 1 THEN 'Y' ELSE 'N' END) AS CrossDBChaining
		,MAX(CASE WHEN config.name = 'remote access' AND config.value = 1 THEN 'Y' ELSE 'N' END) AS RemoteConnections
		,MAX(CASE WHEN config.name = 'remote proc trans' AND config.value = 1 THEN 'Y' ELSE 'N' END) AS ReqDistTransaction
		,MAX(CASE WHEN config.name = 'fill factor (%)' THEN config.value END) AS DefaultFillFactor
		,MAX(CASE WHEN config.name = 'backup checksum default' AND config.value = 1 THEN 'Y' ELSE 'N' END) AS ChecksumBackup
		,MAX(CASE WHEN config.name = 'backup compression default' AND config.value = 1 THEN 'Y' ELSE 'N' END) AS CompressBackup
		,@DefaultData AS DataPath
		,@DefaultLog AS LogPath
		,@DefaultBackup AS BackupPath
		,MAX(CASE WHEN config.name = 'clr enabled' AND config.value = 1 THEN 'Y' ELSE 'N' END) AS CLREnabled
		,MAX(CASE WHEN config.name = 'clr strict security' AND config.value = 1 THEN 'Y'
				WHEN @Version < 14 THEN ''
				ELSE 'N'
			END) AS CLRStrictSecurity
		,MAX(CASE WHEN config.name = 'filestream access level' THEN CASE CAST(config.value AS INT)
				WHEN 0 THEN 'Disabled'
				WHEN 1 THEN 'Transact-SQL access enabled'
				WHEN 2 THEN 'Full access enabled'
		END END) AS FILESTREAMAccessLevel
		,MAX(CASE WHEN config.name = 'server trigger recursion' AND config.value = 1 THEN 'Y' ELSE 'N' END) AS RecursiveTriggers
		,MAX(CASE WHEN config.name = 'optimize for ad hoc workloads' AND config.value = 1 THEN 'Y' ELSE 'N' END) AS OptimizeForAdHocWorkloads
		,MAX(CASE WHEN config.name = 'scan for startup procs' AND config.value = 1 THEN 'Y' ELSE 'N' END) AS ScanForStartupProcs
		,MAX(CASE WHEN config.name = 'cost threshold for parallelism' THEN config.value END) AS CostThresholdParallelism
		,MAX(os.cpu_count) AS HostCPUs
		,MAX(CASE WHEN config.name = 'max degree of parallelism' THEN config.value END) AS MAXDOP
		,@TempDbFiles AS TempDbFiles
		,MAX(CASE WHEN config.name = 'Database Mail XPs' AND config.value = 1 THEN 'Y' ELSE 'N' END) AS DBMailEnabled
		,MAX(CASE WHEN config.name = 'remote admin connections' AND config.value = 1 THEN 'Y' ELSE 'N' END) AS DACEnabled
		,@FailSafeOperator as FailsafeOperator
		,@DatabaseMailProfile as DatabaseMailProfile
		,CAST(SERVERPROPERTY('Collation') AS NVARCHAR(128)) AS Collation
FROM	sys.configurations config
		CROSS JOIN sys.dm_os_sys_info os;

---- http://blog.waynesheffield.com/wayne/archive/2017/09/registry-sql-server-startup-parameters/

--DECLARE @RegHive    VARCHAR(50),
--        @RegKey     VARCHAR(100);
 
--SET @RegHive = 'HKEY_LOCAL_MACHINE';
--SET @RegKey  = 'Software\Microsoft\MSSQLSERVER\MSSQLServer\Parameters';
 
---- Get all of the arguments / parameters when starting up the service.
--DECLARE @SQLArgs TABLE (
--    Value   VARCHAR(50),
--    Data    VARCHAR(500),
--    ArgNum  AS CONVERT(INTEGER, REPLACE(Value, 'SQLArg', '')));
 
--INSERT INTO @SQLArgs
--EXECUTE master.sys.xp_instance_regenumvalues @RegHive, @RegKey;
 
--SELECT  Value AS StartupParam
--       ,Data AS StartupData
--FROM    @SQLArgs;

SELECT	value_name AS StartupParam
		,value_data AS StartupData
FROM	sys.dm_server_registry  
WHERE	registry_key LIKE N'%Parameters';  

DBCC TRACESTATUS;


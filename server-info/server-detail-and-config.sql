
SELECT	SERVERPROPERTY('ServerName') AS HostName -- Both the Windows server and instance information associated with a specified instance of SQL Server.
		,SERVERPROPERTY('MachineName') AS MachineName -- For a clustered instance, Windows computer name on which the server instance is running.
		,DEFAULT_DOMAIN() AS Domain
		,ec.local_net_address AS IP
		,ec.local_tcp_port AS Port
		--,SERVERPROPERTY('Edition') AS Product -- Installed product edition of the instance of SQL Server.
		,CASE WHEN CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)) LIKE '8.%' THEN '2000'
			WHEN CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)) LIKE '9.%' THEN '2005'
			WHEN CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)) LIKE '10.0%' THEN '2008'
			WHEN CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)) LIKE '10.5%' THEN '2008 R2'
			WHEN CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)) LIKE '11.%' THEN '2012'
			WHEN CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)) LIKE '12.%' THEN '2014'
			WHEN CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)) LIKE '13.%' THEN '2016'
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
		,SERVERPROPERTY('ProductVersion') AS Version -- Version of the instance of SQL Server, in the form of 'major.minor.build.revision'.
		,ISNULL(SERVERPROPERTY('ProductUpdateLevel'),'') AS CU -- Update level of the current build.
		,ISNULL(SERVERPROPERTY('IsClustered'),0) AS Cluster -- Server instance is configured in a failover cluster.
		,ISNULL(SERVERPROPERTY('IsHadrEnabled'),0) AS AG -- Always On Availability Groups is enabled on this server instance.
		,CAST(ROUND(os.physical_memory_kb / 1024.0 / 1024.0,0) AS INT) AS Memory -- Specifies the total amount of physical memory on the machine. Not nullable. Converted to GB.
		,os.cpu_count AS CPU -- Specifies the number of logical CPUs on the system. Not nullable.
		,wi.windows_release AS OSVersion -- For Windows, returns the release number. Cannot be NULL.
		,CASE WHEN wi.windows_release = 6.1 THEN '2008 R2'
			WHEN wi.windows_release = 6.2 THEN '2012'
			WHEN wi.windows_release = 6.3 THEN '2012 R2'
			WHEN wi.windows_release = 10.0 THEN '2016'
			ELSE 'UNKNOWN'
		END AS OS -- https://msdn.microsoft.com/library/ms724832%28vs.85%29.aspx?f=255&MSPPError=-2147217396
		,REPLACE(wi.windows_service_pack_level,'Service Pack ','') AS OSSP -- For Windows, returns the service pack number. Cannot be NULL.
FROM	sys.dm_os_sys_info os
		CROSS JOIN sys.dm_os_windows_info wi
		CROSS JOIN sys.dm_exec_connections ec
WHERE	ec.session_id = @@SPID;


DECLARE @LoginAuditing INT
		,@DefaultData NVARCHAR(512)
		,@DefaultLog NVARCHAR(512)
		,@DefaultBackup NVARCHAR(512)
		,@NUMANodes INT
		,@TempDbFiles INT;

EXEC master..xp_instance_regread 
    @rootkey='HKEY_LOCAL_MACHINE',
    @key='SOFTWARE\Microsoft\MSSQLServer\MSSQLServer',
    @value_name='AuditLevel',
    @value=@LoginAuditing OUTPUT;

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

EXEC master.dbo.xp_instance_regread 
    @rootkey='HKEY_LOCAL_MACHINE',
    @key='SOFTWARE\Microsoft\MSSQLServer\MSSQLServer',
    @value_name='BackupDirectory',
    @value=@DefaultBackup OUTPUT;

/*
http://www.sqlpassion.at/archive/2016/10/17/how-many-numa-nodes-do-i-have/
For every available NUMA node SQL Server creates one dedicated Memory Node (besides Memory Node ID 64, which is always
present for the Dedicated Admin Connection).
*/
SELECT	@NUMANodes = COUNT(*)
FROM	sys.dm_os_memory_nodes
WHERE	memory_node_id <> 64;

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
		,MAX(CASE WHEN config.name = 'backup compression default' AND config.value = 1 THEN 'Y' ELSE 'N' END) AS CompressBackup
		,@DefaultData AS DataPath
		,@DefaultLog AS LogPath
		,@DefaultBackup AS BackupPath
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
		,@NUMANodes AS NUMANodes
		,MAX(CASE WHEN config.name = 'max degree of parallelism' THEN config.value END) AS MAXDOP
		,@TempDbFiles AS TempDbFiles
		,MAX(CASE WHEN config.name = 'Database Mail XPs' AND config.value = 1 THEN 'Y' ELSE 'N' END) AS DBMailEnabled
		,MAX(CASE WHEN config.name = 'remote admin connections' AND config.value = 1 THEN 'Y' ELSE 'N' END) AS DACEnabled
FROM	sys.configurations config
		CROSS JOIN sys.dm_os_sys_info os;

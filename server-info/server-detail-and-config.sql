
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
		,SERVERPROPERTY('InstanceDefaultDataPath') AS DataPath -- Name of the default path to the instance data files.
		,SERVERPROPERTY('InstanceDefaultLogPath') AS LogPath -- Name of the default path to the instance log files.
FROM	sys.dm_os_sys_info os
		CROSS JOIN sys.dm_os_windows_info wi
		CROSS JOIN sys.dm_exec_connections ec
WHERE	ec.session_id = @@SPID;


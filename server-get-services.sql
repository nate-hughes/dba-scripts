
select	@@SERVERNAME AS servername
		,DEFAULT_DOMAIN() as domain
		,servicename
		,startup_type
		,status
		,last_startup_time
		,service_account
		,CASE is_clustered
			WHEN 'Y' THEN 1
			WHEN 'N' THEN 0
		END AS is_clustered
		,cluster_nodename
		,CASE instant_file_initialization_enabled
			WHEN 'Y' THEN 1
			WHEN 'N' THEN 0
		END AS instant_file_initialization_enabled
from	sys.dm_server_services;

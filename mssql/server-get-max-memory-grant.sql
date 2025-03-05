USE master;  

--SELECT * FROM sys.resource_governor_external_resource_pools;
SELECT * FROM sys.resource_governor_resource_pools;  
SELECT * FROM sys.resource_governor_workload_groups;  

-- MAX Memory Grant calc: (Maximum SQL Server memory * 90%) * 20%
-- RG Memory Grant calc: (Maximum SQL Server memory * 90%) * 20% * sys.resource_governor_resource_pools.max_memory_percent
SELECT  CAST(value_in_use AS INT) AS MaxMemory_MB
		,TRY_CONVERT(INT,(CAST(value_in_use AS INT) * .9) * .2) AS MaxGrant_MB
		,TRY_CONVERT(INT,(CAST(value_in_use AS INT) * .9) * .2 * .5) AS ResourceGov_MB
FROM    sys.configurations
WHERE   name = 'Max Server Memory (MB)';


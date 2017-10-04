USE master;
GO

-- WSFC cluster node configuration: reports status of each member node of the cluster
SELECT  member_name
       ,member_type
       ,member_type_desc
       ,member_state
       ,member_state_desc
       ,number_of_quorum_votes
FROM    sys.dm_hadr_cluster_members;
GO

-- WSFC cluster network: contains one row for each network adapter in the cluster
SELECT  member_name
       ,network_subnet_ip
       ,network_subnet_ipv4_mask
       ,network_subnet_prefix_length
       ,is_public
       ,is_ipv4
FROM    sys.dm_hadr_cluster_networks;
GO

-- Availability groups
-- reports current health statuses
SELECT  primary_replica
       ,primary_recovery_health_desc
       ,synchronization_health_desc
FROM    sys.dm_hadr_availability_group_states;
GO
-- reports metadata cached in SQL Server process space
SELECT  group_id
       ,name
       ,resource_id
       ,resource_group_id
       ,failure_condition_level
       ,health_check_timeout
       ,automated_backup_preference
       ,automated_backup_preference_desc
FROM    sys.availability_groups;
GO
-- reports metadata stored in WSFC Cluster
SELECT  group_id
       ,name
       ,resource_id
       ,resource_group_id
       ,failure_condition_level
       ,health_check_timeout
       ,automated_backup_preference
       ,automated_backup_preference_desc
FROM    sys.availability_groups_cluster;
GO

-- Availability replicas
-- reports current health statuses
SELECT  replica_id
       ,role_desc
       ,recovery_health_desc
       ,synchronization_health_desc
FROM    sys.dm_hadr_availability_replica_states;
GO
-- reports state information locally cached in SQL Server
SELECT  replica_id
       ,role_desc
       ,connected_state_desc
       ,synchronization_health_desc
FROM    sys.dm_hadr_availability_replica_states;
GO
-- reports configuration data cached locally in SQL Server
SELECT  replica_server_name
       ,replica_id
       ,availability_mode_desc
       ,endpoint_url
FROM    sys.availability_replicas;
GO
-- reports state information from WSFC cluster
SELECT  replica_server_name
       ,join_state_desc
FROM    sys.dm_hadr_availability_replica_cluster_states;
GO

-- Availability databases
-- reports current health statuses
SELECT  dc.database_name
       ,dr.database_id
       ,dr.synchronization_state_desc
       ,dr.suspend_reason_desc
       ,dr.synchronization_health_desc
FROM    sys.dm_hadr_database_replica_states     dr
        JOIN sys.availability_databases_cluster dc
            ON dr.group_database_id = dc.group_database_id
WHERE   dr.is_local = 1;
GO
-- reports configuration information from WSFC cluster
SELECT  group_id
       ,group_database_id
       ,database_name
FROM    sys.availability_databases_cluster;
GO
-- reports state information locally cached in SQL Server
SELECT  group_database_id
       ,database_name
       ,is_failover_ready
FROM    sys.dm_hadr_database_replica_cluster_states;
GO
-- reports identity and state information, such as LSN progress information for logs of primary and secondary replicas
SELECT  database_id
       ,synchronization_state_desc
       ,synchronization_health_desc
       ,last_hardened_lsn
       ,redo_queue_size
       ,log_send_queue_size
FROM    sys.dm_hadr_database_replica_states;
GO

/*
Using change data capture
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.SQLServer.CommonDBATasks.CDC.html
*/

-- enable CDC
exec msdb.dbo.rds_cdc_enable_db 'database_name'
GO

--disable CDC
exec msdb.dbo.rds_cdc_disable_db 'database_name'
GO

--Begin tracking a table
exec sys.sp_cdc_enable_table   
   @source_schema           = N'source_schema'
,  @source_name             = N'source_name'
,  @role_name               = N'role_name'
--The following parameters are optional:
--, @capture_instance       = 'capture_instance'
--, @supports_net_changes   = supports_net_changes
--, @index_name             = 'index_name'
--, @captured_column_list   = 'captured_column_list'
--, @filegroup_name         = 'filegroup_name'
--, @allow_partition_switch = 'allow_partition_switch'
;  

--View CDC configuration
exec sys.sp_cdc_help_change_data_capture 
--The following parameters are optional and must be used together.
--  'schema_name', 'table_name'
;

-- Show configuration for each parameter on either primary and secondary replicas. 
exec rdsadmin.dbo.rds_show_configuration 'cdc_capture_maxtrans';

--To set values on secondary. These are used after failover.
exec rdsadmin.dbo.rds_set_configuration 'cdc_capture_maxtrans', 1000;

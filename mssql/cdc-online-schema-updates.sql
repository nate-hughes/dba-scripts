/* 
Debezium connector for SQL Server
https://debezium.io/documentation/reference/connectors/sqlserver.html#online-schema-updates
*/

/* Online schema updates */
-- 1. Apply all changes to the source table schema.
ALTER TABLE [schemaname].[tablename] ADD [columnname] VARCHAR(50) NULL;

-- 2.Create a new capture table for the update source table by running the sys.sp_cdc_enable_table stored procedure with a unique value for the parameter @capture_instance.
EXEC sys.sp_cdc_enable_table
	@source_schema = 'schemaname'
	,@source_name = 'tablename'
	,@role_name = 'cdc_admin'
	,@capture_instance = 'schemaname_tablename_v2';
GO

-- 3. When Debezium starts streaming from the new capture table, you can drop the old capture table by running the sys.sp_cdc_disable_table stored procedure with the parameter
--    @capture_instance set to the old capture instance name.
EXEC sys.sp_cdc_disable_table
	@source_schema = 'schemaname'
	,@source_name = 'tablename'
	,@capture_instance = 'schemaname_tablename';
GO


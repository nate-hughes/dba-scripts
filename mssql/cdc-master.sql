/* Enable CDC for Database
https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sys-sp-cdc-enable-db-transact-sql?view=sql-server-ver15
*/
USE MarletteUAT;
GO
EXEC sys.sp_cdc_enable_db;
GO

/* Enable CDC for Table(s)
https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sys-sp-cdc-enable-table-transact-sql?view=sql-server-ver15
*/
EXEC sys.sp_cdc_enable_table 
	@source_schema = N'schemaname' 
	,@source_name = N'tablename'
    --,@capture_instance = N'schemaname_tablename'
	,@role_name = N'cdc_admin';
GO

/* View CDC configuration
https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sys-sp-cdc-enable-table-transact-sql?view=sql-server-ver15
https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sys-sp-cdc-help-jobs-transact-sql?view=sql-server-ver15
*/
EXEC sys.sp_cdc_help_change_data_capture;
GO
EXEC sys.sp_cdc_help_jobs;
GO

SELECT * FROM [cdc].[captured_columns];
SELECT * FROM [cdc].[change_tables];
SELECT * FROM [cdc].[ddl_history];
SELECT * FROM [cdc].[index_columns];
SELECT * FROM [cdc].[lsn_time_mapping];
SELECT * FROM [msdb].[dbo].[cdc_jobs];
GO

/* Update CDC SQL Agent jobs
https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sys-sp-cdc-change-job-transact-sql?view=sql-server-ver15
cdc.{DatabaseName}_capture
cdc.{DatabaseName}_cleanup
*/
-- change capture interval to 5 seconds (default)
EXECUTE sys.sp_cdc_change_job   
    @job_type = N'capture'
    ,@pollinginterval = 5; -- in seconds
GO
-- job must be restarted before new settings take effect
EXEC sys.sp_cdc_stop_job @job_type = 'capture';
EXEC sys.sp_cdc_start_job @job_type = 'capture';
GO
-- change data retention to 3 days (default)
EXECUTE sys.sp_cdc_change_job   
    @job_type = N'cleanup'
    ,@retention = 4320; -- in minutes
GO
-- job must be restarted before new settings take effect
EXEC sys.sp_cdc_stop_job @job_type = 'cleanup';
EXEC sys.sp_cdc_start_job @job_type = 'cleanup';
GO

/* View CDC captured data
https://docs.microsoft.com/en-us/sql/relational-databases/system-functions/cdc-fn-cdc-get-all-changes-capture-instance-transact-sql?view=sql-server-ver15

The _$operation column tells us what operation was logged:
1 = delete
2 = insert
3 = update (captured column values are those before the update operation)
4 = update (captured column values are those after the update operation)
*/
DECLARE	@from_lsn binary(10) = sys.fn_cdc_get_min_lsn('capture_instance')
		,@to_lsn binary(10) = sys.fn_cdc_get_max_lsn();

SELECT	*
FROM	cdc.fn_cdc_get_all_changes_sst_funding_archive (@from_lsn, @to_lsn, N'all');  
GO  

SELECT	*
FROM	[cdc].[sst_funding_archive_CT];
GO

/* Disable CDC for Table(s)
Drops the CDC change table and system functions associated with the specified source table and capture instance.
https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sys-sp-cdc-disable-table-transact-sql?view=sql-server-ver15
*/
EXECUTE sys.sp_cdc_disable_table   
    @source_schema = N'schemaname',   
    @source_name = N'tablename',  
    @capture_instance = N'capture_instance';  
GO

/* Disable CDC for Database
https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sys-sp-cdc-disable-db-transact-sql?view=sql-server-ver15
Disables CDC for all currently enabled tables in the database. All system objects related to CDC are dropped.
*/
EXECUTE sp_cdc_disable_db;
GO


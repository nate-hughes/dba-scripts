use tempdb;
GO
select name, * from sys.sysfiles;
GO

exec msdb.dbo.rds_shrink_tempdbfile
	@temp_filename = N'tempdev'
	,@target_size = 1024; -- in MB
GO

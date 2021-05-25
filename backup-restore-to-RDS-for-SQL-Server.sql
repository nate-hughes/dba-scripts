/*
Migrating SQL Server to Amazon RDS using native backup and restore
https://aws.amazon.com/blogs/database/migrating-sql-server-to-amazon-rds-using-native-backup-and-restore/
*/

USE master;
GO

EXEC msdb.dbo.rds_restore_database
	@restore_db_name='DatabaseName',
	@s3_arn_to_restore_from='arn:aws:s3:::bucketname/sqlserverbackups/DatabaseName_full.bak',
	@with_norecovery=1,
	@type='FULL';
GO

SELECT * FROM msdb.dbo.rds_fn_task_status(NULL,0);
GO

EXEC msdb.dbo.rds_restore_database
	@restore_db_name='DatabaseName',
	@s3_arn_to_restore_from='arn:aws:s3:::bucketname/sqlserverbackups/DatabaseName_diff.bak',
	@type='DIFFERENTIAL',
	@with_norecovery=1;
GO

SELECT * FROM msdb.dbo.rds_fn_task_status(NULL,0);
GO

EXEC msdb.dbo.rds_restore_log
	@restore_db_name='DatabaseName',
	@s3_arn_to_restore_from='arn:aws:s3:::bucketname/sqlserverbackup/DatabaseName_log.trn',
	@with_norecovery=0;
go

SELECT * FROM msdb.dbo.rds_fn_task_status(NULL,0);
GO


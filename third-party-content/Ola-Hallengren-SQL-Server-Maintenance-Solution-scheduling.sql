USE msdb;
go

DECLARE @schedules TABLE (name NVARCHAR(128));

INSERT INTO @schedules (name)
SELECT	name
FROM	dbo.sysschedules;

IF NOT EXISTS(SELECT 1 FROM @schedules WHERE name = 'sched: Daily 2 am')
	exec sp_add_schedule 'sched: Daily 2 am',	1,	4,	1,	1,	0,	0,	0,	20131001,	99991231,	20000,	235959
IF NOT EXISTS(SELECT 1 FROM @schedules WHERE name = 'sched: Daily 12 am')
	exec sp_add_schedule 'sched: Daily 12 am',	1,	4,	1,	1,	0,	0,	0,	20131001,	99991231,	0,	235959;
IF NOT EXISTS(SELECT 1 FROM @schedules WHERE name = 'sched: Sun 12 am')
	exec sp_add_schedule 'sched: Sun 12 am',	1,	8,	1,	1,	0,	0,	1,	20131001,	99991231,	0,	235959;
IF NOT EXISTS(SELECT 1 FROM @schedules WHERE name = 'sched: Sun 1 am')
	exec sp_add_schedule 'sched: Sun 1 am',	1,	8,	1,	1,	0,	0,	1,	20131001,	99991231,	10000,	235959;
IF NOT EXISTS(SELECT 1 FROM @schedules WHERE name = 'sched: Sun 8:30 am')
	exec sp_add_schedule 'sched: Sun 8:30 am',	1,	8,	1,	1,	0,	0,	1,	20131001,	99991231,	83000,	235959;

exec sp_attach_schedule @job_name='CommandLog Cleanup', @schedule_name='sched: Daily 2 am';
exec sp_attach_schedule @job_name='DatabaseBackup - SYSTEM_DATABASES - FULL', @schedule_name='sched: Daily 12 am';
exec sp_attach_schedule @job_name='DatabaseBackup - USER_DATABASES - FULL', @schedule_name='sched: Sun 12 am';
exec sp_attach_schedule @job_name='DatabaseBackup - USER_DATABASES - DIFF', @schedule_name='sched: Daily 12 am';
exec sp_attach_schedule @job_name='DatabaseIntegrityCheck - SYSTEM_DATABASES', @schedule_name='sched: Sun 1 am';
exec sp_attach_schedule @job_name='DatabaseIntegrityCheck - USER_DATABASES', @schedule_name='sched: Sun 1 am';
exec sp_attach_schedule @job_name='IndexOptimize - USER_DATABASES', @schedule_name='sched: Sun 8:30 am';
EXEC sp_attach_schedule @job_name='Output File Cleanup', @schedule_name='sched: Daily 2 am';
exec sp_attach_schedule @job_name='sp_delete_backuphistory', @schedule_name='sched: Daily 2 am';
exec sp_attach_schedule @job_name='sp_purge_jobhistory', @schedule_name='sched: Daily 2 am';
exec sp_attach_schedule @job_name='syspolicy_purge_history', @schedule_name='sched: Daily 2 am';

EXEC msdb.dbo.sp_update_job @job_name='CommandLog Cleanup', @notify_level_email=2, @notify_level_netsend=2, @notify_level_page=2, @notify_email_operator_name=N'DBAs';
EXEC msdb.dbo.sp_update_job @job_name='DatabaseBackup - SYSTEM_DATABASES - FULL', @notify_level_email=2, @notify_level_netsend=2, @notify_level_page=2, @notify_email_operator_name=N'DBAs';
EXEC msdb.dbo.sp_update_job @job_name='DatabaseBackup - USER_DATABASES - FULL', @notify_level_email=2, @notify_level_netsend=2, @notify_level_page=2, @notify_email_operator_name=N'DBAs';
EXEC msdb.dbo.sp_update_job @job_name='DatabaseBackup - USER_DATABASES - DIFF', @notify_level_email=2, @notify_level_netsend=2, @notify_level_page=2, @notify_email_operator_name=N'DBAs';
EXEC msdb.dbo.sp_update_job @job_name='DatabaseBackup - USER_DATABASES - LOG', @notify_level_email=2, @notify_level_netsend=2, @notify_level_page=2, @notify_email_operator_name=N'DBAs';
EXEC msdb.dbo.sp_update_job @job_name='DatabaseIntegrityCheck - SYSTEM_DATABASES', @notify_level_email=2, @notify_level_netsend=2, @notify_level_page=2, @notify_email_operator_name=N'DBAs';
EXEC msdb.dbo.sp_update_job @job_name='DatabaseIntegrityCheck - USER_DATABASES', @notify_level_email=2, @notify_level_netsend=2, @notify_level_page=2, @notify_email_operator_name=N'DBAs';
EXEC msdb.dbo.sp_update_job @job_name='IndexOptimize - USER_DATABASES', @notify_level_email=2, @notify_level_netsend=2, @notify_level_page=2, @notify_email_operator_name=N'DBAs';
EXEC msdb.dbo.sp_update_job @job_name='Output File Cleanup', @notify_level_email=2, @notify_level_netsend=2, @notify_level_page=2, @notify_email_operator_name=N'DBAs';
EXEC msdb.dbo.sp_update_job @job_name='sp_delete_backuphistory', @notify_level_email=2, @notify_level_netsend=2, @notify_level_page=2, @notify_email_operator_name=N'DBAs';
EXEC msdb.dbo.sp_update_job @job_name='sp_purge_jobhistory', @notify_level_email=2, @notify_level_netsend=2, @notify_level_page=2, @notify_email_operator_name=N'DBAs';
EXEC msdb.dbo.sp_update_job @job_name='syspolicy_purge_history', @notify_level_email=2, @notify_level_netsend=2, @notify_level_page=2, @notify_email_operator_name=N'DBAs';

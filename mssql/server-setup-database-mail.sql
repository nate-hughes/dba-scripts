-- pre-req: Service Broker and Database Mail XPs enabled
select is_broker_enabled from sys.databases where name = 'msdb';
select * from sys.configurations where name = 'database mail xps';
go

-- if need to enable Database Mail XPs
-- need Show Advanced Options enabled
select * from sys.configurations where name = 'show advanced options';
go
-- if not, enabled and remember to disable after
EXEC sys.sp_configure 'show advanced options', N'1';
RECONFIGURE;
go
-- enable Database Mail XPs
EXEC sys.sp_configure 'database mail xps', N'1';
RECONFIGURE;
go
-- if you enabled Show Advanced Options, disable it now
EXEC sys.sp_configure 'show advanced options', N'0';
RECONFIGURE;
go

-- create Database Mail account
declare @account_id int
		,@profile_id int;

EXEC msdb.dbo.sysmail_add_account_sp
	@account_name = N'SQLAdmin@company.com'
	,@email_address = N'SQLAdmin@company.com'
	,@display_name = N'SQLAdmin@company.com'
	,@mailserver_name = N'smtp.domain.net'
	,@account_id = @account_id OUTPUT;

-- create Database Mail profile
EXEC msdb.dbo.sysmail_add_profile_sp
	@profile_name = N'DBA'
	,@profile_id = @profile_id OUTPUT;

-- add account to profile
EXEC msdb.dbo.sysmail_add_profileaccount_sp
	@profile_id = @profile_id
	,@account_id = @account_id
	,@sequence_number = 1;

-- grant access to use Database Mail profile
EXEC msdb.dbo.sysmail_add_principalprofile_sp
	@principal_id = 0
	,@profile_id = @profile_id
	,@is_default = 1;
go

/*
enable on sql server agent
prop > alert system
enale profile
include body...
enable fail-safe...email
restart sql agent
*/

EXEC msdb.dbo.sp_addrolemember
	@rolename = 'DatabaseMailUserRole'
    ,@membername = '<user or role name>';
GO
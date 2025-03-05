USE [master]
GO

EXEC master.dbo.sp_serveroption @server=N'LinkedServerName', @optname=N'name', @optvalue=N'LinkedServerName_OLD';
EXEC master.dbo.sp_serveroption @server=N'LinkedServerName_NEW', @optname=N'name', @optvalue=N'LinkedServerName';

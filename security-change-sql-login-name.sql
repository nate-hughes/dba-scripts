-- change LOGIN name
USE [master];
ALTER LOGIN [current-login-name]
WITH NAME = [new-login-name];
GO

-- change database USER name
USE [db_name];
GO
ALTER USER [current-user-name]
WITH NAME = [new-user-name];
GO
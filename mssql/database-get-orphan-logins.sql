/*
List the users and corresponding security identifiers (SID) in the current database that are not linked to any login.
User, login, and password must be NULL or not specified.
*/
USE [?]
GO
EXEC sys.sp_change_users_login @Action = 'report';
GO

/*
Links a user entry in the sys.database_principals system catalog view in the current database to a SQL Server login of the same name. If a login with the same name does not exist,
one will be created. Examine the result from the Auto_Fix statement to confirm that the correct link is in fact made. Avoid using Auto_Fix in security-sensitive situations.

When you use Auto_Fix, you must specify user and password if the login does not already exist, otherwise you must specify user but password will be ignored. Login must be NULL.
User must be a valid user in the current database. The login cannot have another user mapped to it.
*/
USE [?]
GO
EXEC sys.sp_change_users_login
	@Action = 'auto_fix'
	,@UserNamePattern = 'database_user' -- name of a user in the current database
	,@LoginName = 'sql_login' -- name of a SQL Server login
	,@Password = 'new_pwd'; -- if a matching login does not exist, sp creates a new login and assigns this password
GO

/*
Links the specified user in the current database to an existing SQL Server login.
*/
USE [?]
GO
EXEC sys.sp_change_users_login
	@Action = 'update_one'
	,@UserNamePattern = 'database_user' -- name of a user in the current database
	,@LoginName = 'sql_login'; -- name of a SQL Server login
GO

SET NOCOUNT ON;

DECLARE @Login NVARCHAR(128)
       ,@SQL   VARCHAR(MAX);

SET @Login = N'applogin';

-- GRANT SERVER LEVEL PERMISSIONS --
SELECT  pri.name                                   AS Login
       ,per.state_desc COLLATE DATABASE_DEFAULT + ' ' + per.permission_name COLLATE DATABASE_DEFAULT + ' TO ['
        + pri.name COLLATE DATABASE_DEFAULT + '];' AS GrantServerPermissionSQL
FROM    sys.server_permissions           per
        INNER JOIN sys.server_principals pri
            ON per.grantee_principal_id = pri.principal_id
WHERE   per.class_desc = 'SERVER'
AND     pri.type IN ('S', 'U', 'G') -- SQL_LOGIN, WINDOWS_LOGIN, WINDOWS_GROUP
AND     pri.is_disabled = 0
AND     pri.name = ISNULL(@Login, pri.name)
ORDER BY pri.name;

-- GRANT SERVER LEVEL ROLES --
SELECT  pri.name                                                                                       AS Login
       ,'EXEC sp_addrolemember @rolename = ''' + rpri.name + ''', @membername = ''' + pri.name + ''';' AS GrantServerRoleSQL
FROM    sys.server_principals              pri
        INNER JOIN sys.server_role_members rm
            ON pri.principal_id = rm.member_principal_id
        INNER JOIN sys.server_principals   rpri
            ON rpri.principal_id = rm.role_principal_id
WHERE   pri.type IN ('S', 'U', 'G') -- SQL_LOGIN, WINDOWS_LOGIN, WINDOWS_GROUP
AND     pri.is_disabled = 0
AND     pri.name = ISNULL(@Login, pri.name);

-- GRANT DATABASE LEVEL PERMISSIONS --
CREATE TABLE #Logins (sid VARBINARY(85));

INSERT INTO #Logins (sid)
SELECT  sid
FROM    sys.server_principals
WHERE   type IN ('S', 'U', 'G') -- SQL_LOGIN, WINDOWS_LOGIN, WINDOWS_GROUP
AND     is_disabled = 0
AND     name = ISNULL(@Login, name)
AND     principal_id <> 1; -- sa

CREATE TABLE #DBSecurity (RowId INT IDENTITY(1, 1), DBName NVARCHAR(128), SQLStmt VARCHAR(MAX));

SET @SQL =
    'USE [?];
INSERT INTO #DBSecurity (DBName, SQLStmt)
SELECT	DB_NAME()
		, ''USE [?];''
UNION ALL
SELECT	DB_NAME()
		, ''IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '''''' + dp.name + '''''') AND EXISTS (SELECT 1 FROM sys.server_principals WHERE name = '''''' + sp.name + '''''') CREATE USER ['' + dp.name + ''] FOR LOGIN ['' + sp.name + ''];''
FROM	sys.database_principals dp
		INNER JOIN sys.server_principals sp ON dp.sid = sp.sid
		INNER JOIN #Logins tmp ON tmp.sid = dp.sid
UNION ALL
SELECT	DB_NAME()
		, ''EXEC sp_addrolemember @rolename = '''''' + dr.name + '''''', @membername = '''''' + dp.name + '''''';''
FROM	sys.database_principals dp
		INNER JOIN sys.database_role_members rm ON rm.member_principal_id = dp.principal_id
		INNER JOIN sys.database_principals dr ON rm.role_principal_id = dr.principal_id
		INNER JOIN #Logins tmp ON tmp.sid = dp.sid
UNION ALL
SELECT	DB_NAME()
		, ''IF EXISTS (SELECT 1 FROM sys.objects WHERE name = '''''' + o.name + '''''') AND EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '''''' + dp.name + '''''') '' + p.state_desc + '' '' + p.permission_name + '' ON ['' + s.name + ''].['' + o.name collate database_default + ''] TO ['' + dp.name + ''];''
FROM	sys.database_principals dp
		INNER JOIN sys.database_permissions p on p.grantee_principal_id = dp.principal_id
		INNER JOIN sys.objects o on p.major_id = o.object_id
		INNER JOIN sys.schemas s on o.schema_id = s.schema_id
		INNER JOIN #Logins tmp ON tmp.sid = dp.sid;
';
		
EXEC sys.sp_MSforeachdb @SQL;

SELECT  DBName
       ,SQLStmt
FROM    #DBSecurity
ORDER BY RowId;

DROP TABLE #Logins;
DROP TABLE #DBSecurity;

-- SET DEFAULT DB --
SELECT  pri.name                                                                                      AS Login
       ,'ALTER LOGIN [' + pri.name + '] WITH DEFAULT_DATABASE = [' + pri.default_database_name + '];' AS SetDefaultDBSQL
FROM    sys.server_principals pri
WHERE   pri.type IN ('S', 'U', 'G') -- SQL_LOGIN, WINDOWS_LOGIN, WINDOWS_GROUP
AND     pri.is_disabled = 0
AND     pri.name = ISNULL(@Login, pri.name)
ORDER BY pri.name;


-- Windows logins and groups
SELECT  N'CREATE LOGIN [' + sp.name + '] FROM WINDOWS;' AS [-- Windows Logins to be Created --]
FROM    master.sys.server_principals AS sp
WHERE   sp.type IN ('U', 'G')
AND     sp.is_disabled = 0
AND     sp.name NOT LIKE 'NT [AS]%\%'
ORDER BY sp.name;

-- SQL Server logins
SELECT  N'CREATE LOGIN [' + sp.name + ']'
		+ ' ' + 'WITH PASSWORD=0x' + CONVERT(NVARCHAR(MAX), l.password_hash, 2) + N' HASHED'
		+ ' ' + ', CHECK_POLICY='
			+ CASE l.is_policy_checked
				WHEN 1 THEN 'ON'
				WHEN 0 THEN 'OFF'
			END
		+ ' ' + ', CHECK_EXPIRATION='
			+ CASE l.is_expiration_checked
				WHEN 1 THEN 'ON'
				WHEN 0 THEN 'OFF'
			END
		+ ' ' + ',  DEFAULT_DATABASE=[' + l.default_database_name + N']'
		+ ' ' + ', SID=0x' + CONVERT(NVARCHAR(MAX), sp.sid, 2)
		+ N';' AS [-- SQL Server Logins to be Created --]
FROM    master.sys.server_principals AS sp
        INNER JOIN master.sys.sql_logins AS l
            ON sp.sid = l.sid
WHERE   sp.type = 'S'
AND     sp.is_disabled = 0
ORDER BY sp.name;

-- Server roles
SELECT  N'CREATE SERVER ROLE [' + sp.name + N'];' AS [-- Server Roles to be Added --]
FROM    sys.server_principals AS sp
WHERE   sp.principal_id >= 100
AND     sp.type = 'R';

-- Server Role permissions
SELECT	'ALTER SERVER ROLE [' + sr.name + '] ADD MEMBER [' + sp.name + '];' AS [-- Server Roles to be Granted --]
FROM	master.sys.server_role_members rm
		JOIN master.sys.server_principals sr ON sr.principal_id = rm.role_principal_id
		JOIN master.sys.server_principals sp ON sp.principal_id = rm.member_principal_id
WHERE	sp.type IN ( 'S', 'U', 'G' )
AND     sp.is_disabled = 0
AND     sp.name NOT LIKE 'NT [AS]%\%'
AND		sp.name <> 'sa';

-- Server Level Permissions
SELECT	CASE
			WHEN p.state_desc <> 'GRANT_WITH_GRANT_OPTION' THEN p.state_desc 
			ELSE 'GRANT' 
		END
		+ ' ' + p.permission_name 
		+ CASE p.class_desc
			WHEN 'SERVER_PRINCIPAL' THEN ' ON LOGIN::' + QUOTENAME(t.name)
			ELSE ''
		END
		+ ' TO [' + sp.name + ']'
		+ CASE
			WHEN p.state_desc <> 'GRANT_WITH_GRANT_OPTION' THEN '' 
			ELSE ' WITH GRANT OPTION' 
		END + ';' COLLATE DATABASE_DEFAULT AS [-- Server Level Permissions to be Granted --] 
FROM    sys.server_permissions AS p
        INNER JOIN sys.server_principals AS sp
            ON p.grantee_principal_id = sp.principal_id
		LEFT OUTER JOIN sys.server_principals AS t
			ON p.major_id = t.principal_id
WHERE	sp.type IN ( 'S', 'U', 'G' )
AND     sp.is_disabled = 0
AND     sp.name NOT LIKE 'NT [AS]%\%'
AND		sp.name <> 'sa'
AND		p.permission_name <> 'connect sql'
ORDER BY sp.name;

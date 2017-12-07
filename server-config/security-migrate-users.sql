
-- Windows logins and groups
SELECT  N'CREATE LOGIN [' + sp.name + '] FROM WINDOWS;'
FROM    master.sys.server_principals AS sp
WHERE   sp.type IN ('U', 'G')
AND     sp.is_disabled = 0
AND     sp.name NOT LIKE 'NT [AS]%\%';

-- SQL Server logins
SELECT  N'CREATE LOGIN [' + sp.name + '] WITH PASSWORD=0x' + CONVERT(NVARCHAR(MAX), l.password_hash, 2)
        + N' HASHED, CHECK_POLICY=OFF, CHECK_EXPIRATION=OFF,  DEFAULT_DATABASE=[' + l.default_database_name
        + N'], SID=0x' + CONVERT(NVARCHAR(MAX), sp.sid, 2) + N';'
FROM    master.sys.server_principals     AS sp
        INNER JOIN master.sys.sql_logins AS l
            ON sp.sid = l.sid
WHERE   sp.type = 'S'
AND     sp.is_disabled = 0;

-- Server roles
SELECT  N'CREATE SERVER ROLE [' + sp.name + N'];'
FROM    sys.server_principals AS sp
WHERE   sp.principal_id >= 100
AND     sp.type = 'R';

-- Permissions
SELECT  p.state_desc + N' ' + p.permission_name + N' TO [' + sp.name COLLATE DATABASE_DEFAULT + N'];'
FROM    sys.server_permissions           AS p
        INNER JOIN sys.server_principals AS sp
            ON p.grantee_principal_id = sp.principal_id;
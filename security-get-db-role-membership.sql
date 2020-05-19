
DECLARE @db_role_sql NVARCHAR(4000);

CREATE TABLE #database_role_members (
	[DatabaseName] VARCHAR(128) NOT NULL,
	[PrincipalName] VARCHAR(128) NOT NULL,
	[IsPrincipalDisabled] BIT NULL,
	[IsPrincipalOrphaned] BIT NOT NULL,
	[RoleName] VARCHAR(128) NOT NULL,
	[IsFixedRole] BIT NOT NULL,
	[RoleOwner] VARCHAR(128) NULL,
);

SET @db_role_sql = N'USE [?];
INSERT #database_role_members (DatabaseName, PrincipalName, IsPrincipalDisabled, IsPrincipalOrphaned, RoleName, IsFixedRole, RoleOwner)
SELECT	DB_NAME()
		,p.name
		,CASE WHEN p.authentication_type <> 0 THEN sp.is_disabled ELSE 0 END
		,CASE WHEN p.type_desc <> ''DATABASE_ROLE'' AND p.authentication_type <> 0 AND sp.sid IS NULL THEN 1 ELSE 0 END
		,r.name
		,r.is_fixed_role
		,r.owning_principal
FROM	sys.database_role_members drm
        INNER JOIN (
			SELECT  rp.principal_id
					,rp.name
					,rp.is_fixed_role
					,suser_sname(op.sid) as owning_principal
			FROM    sys.database_principals rp
					JOIN sys.database_principals op ON rp.owning_principal_id = op.principal_id
			WHERE   rp.type_desc = ''DATABASE_ROLE''
        ) r ON r.principal_id = drm.role_principal_id
        RIGHT JOIN sys.database_principals p ON p.principal_id = drm.member_principal_id
		LEFT JOIN sys.server_principals sp ON p.sid = sp.sid
WHERE   r.name IS NOT NULL;';

EXEC sp_MSforeachdb @db_role_sql;

SELECT	@@SERVERNAME AS ServerName
		,DEFAULT_DOMAIN() AS Domain
		,*
FROM	#database_role_members;

DROP TABLE #database_role_members;

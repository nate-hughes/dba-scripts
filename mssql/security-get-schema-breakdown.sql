DECLARE	@SchemaName NVARCHAR(128) = N'remittance';

-- Database Permissions
SELECT	p.state_desc AS permission_state
		,p.permission_name
		,'ON' AS [on]
		,p.class_desc AS permission_level
		,'' AS [schema_name]
		,'' AS [object_name]
		,'TO' AS [to]
		,USER_NAME(p.grantee_principal_id) AS grantee
		,CASE
			WHEN sp.is_disabled = 1 THEN 'is_disabled'
			WHEN sp.name IS NULL THEN 'is_orphaned'
			ELSE ''
		END AS user_status
FROM	sys.database_permissions p
		JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
		LEFT JOIN sys.server_principals sp ON dp.sid = sp.sid
WHERE	p.class_desc = 'DATABASE'
AND		p.permission_name NOT IN ('CONNECT', 'SHOWPLAN')
AND		dp.name <> 'public'
UNION ALL
-- Schema Permissions
SELECT	p.state_desc
		,p.permission_name
		,'ON'
		,p.class_desc
		,SCHEMA_NAME(p.major_id)
		,'' AS [object_name]
		,'TO'
		,USER_NAME(p.grantee_principal_id)
		,CASE
			WHEN sp.is_disabled = 1 THEN 'is_disabled'
			WHEN sp.sid IS NULL THEN 'is_orphaned'
			ELSE ''
		END AS user_status
FROM	sys.database_permissions p
		JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
		LEFT JOIN sys.server_principals sp ON dp.sid = sp.sid
WHERE	p.class_desc = 'SCHEMA'
AND		p.major_id = SCHEMA_ID(@SchemaName)
UNION ALL
SELECT	p.state_desc
		,p.permission_name
		,'ON'
		,p.class_desc
		,SCHEMA_NAME(o.schema_id)
		,o.name AS [object_name]
		,'TO'
		,USER_NAME(ISNULL(rp.principal_id, p.grantee_principal_id))
		,CASE
			WHEN sp.is_disabled = 1 THEN 'is_disabled'
			WHEN sp.sid IS NULL THEN 'is_orphaned'
			ELSE ''
		END AS user_status
FROM	sys.database_permissions p
		JOIN sys.objects o ON p.major_id = o.object_id
		JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
		LEFT JOIN sys.database_role_members rm ON dp.principal_id = rm.role_principal_id
		LEFT JOIN sys.database_principals rp ON rm.member_principal_id = rp.principal_id
		LEFT JOIN sys.server_principals sp ON sp.sid = ISNULL(rp.sid, dp.sid)
WHERE	p.class_desc = 'OBJECT_OR_COLUMN'
AND		o.schema_id = SCHEMA_ID(@SchemaName)

ORDER BY grantee;


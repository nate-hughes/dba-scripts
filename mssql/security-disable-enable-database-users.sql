
SELECT	'USE [' + DB_NAME() + ']; REVOKE CONNECT FROM [' + name + '];' AS RevokeStmt
		,'USE [' + DB_NAME() + ']; GRANT CONNECT FROM [' + name + '];' AS GrantStmt
FROM	sys.database_principals
WHERE	type_desc IN ('SQL_USER','WINDOWS_GROUP','WINDOWS_USER')
AND		sid NOT IN (0x01, 0x00)
--AND		name NOT LIKE 'CM %'
AND		name <> 'CM Analytics FLRA Service'
ORDER BY 1




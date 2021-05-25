
SELECT	sp.name
		,LOGINPROPERTY (sp.name, 'IsExpired') AS IsExpired
		,LOGINPROPERTY (sp.name, 'DaysUntilExpiration') AS DaysUntilExpiration
FROM	sys.server_principals sp
		JOIN sys.sql_logins sl ON sp.principal_id = sl.principal_id
WHERE	sp.type_desc = 'SQL_LOGIN'
AND		sp.is_disabled = 0
AND		sl.is_expiration_checked = 1
ORDER BY 1

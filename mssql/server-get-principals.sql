
SELECT	@@SERVERNAME AS ServerName
		,DEFAULT_DOMAIN() AS Domain
		,p.name AS PrincipalName
		,p.type
		,p.is_disabled
		,p.create_date
		,p.modify_date
		,p.default_database_name
		,p.default_language_name
		,s.is_policy_checked
		,s.is_expiration_checked
FROM	sys.server_principals p
		LEFT JOIN sys.sql_logins s ON p.sid = s.sid
WHERE	p.type IN ('S', 'U', 'G'); /*SQL login, Windows login, Windows group*/

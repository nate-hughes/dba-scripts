
SELECT	name
		,LOGINPROPERTY([name], 'PasswordLastSetTime') AS 'PasswordChanged'
		,LOGINPROPERTY([name], 'DaysUntilExpiration') AS DaysUntilExpiration
		,LOGINPROPERTY([name], 'IsExpired') AS IsExpired
		,LOGINPROPERTY([name], 'IsLocked') AS IsLocked
FROM	sys.sql_logins
WHERE	is_disabled = 0
AND		is_expiration_checked = 1
AND		(
			-- Show all logins where the password is over 60 days old
			LOGINPROPERTY([name], 'PasswordLastSetTime') < DATEADD(dd, -60, GETDATE())
			-- Show all logins that are Expired
			OR LOGINPROPERTY([name], 'IsExpired') = 1
			-- Show all logins that are Locked
			OR LOGINPROPERTY([name], 'IsLocked') = 1
		)
ORDER BY name;

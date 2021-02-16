-- Show all logins where the password is over 60 days old
SELECT	name
		,LOGINPROPERTY([name], 'PasswordLastSetTime') AS 'PasswordChanged'
FROM	sys.sql_logins
WHERE	LOGINPROPERTY([name], 'PasswordLastSetTime') < DATEADD(dd, -60, GETDATE());
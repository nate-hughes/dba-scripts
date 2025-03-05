DECLARE @name NVARCHAR(128) = N''

SELECT	name
		,is_disabled
		,is_policy_checked
		,LOGINPROPERTY(name, 'BadPasswordCount') AS 'BadPasswordCount'
		,LOGINPROPERTY(name, 'BadPasswordTime') AS 'BadPasswordTime'
		,LOGINPROPERTY(name, 'DaysUntilExpiration') AS 'DaysUntilExpiration'
		,LOGINPROPERTY(name, 'DefaultDatabase') AS 'DefaultDatabase'
		,LOGINPROPERTY(name, 'DefaultLanguage') AS 'DefaultLanguage'
		,LOGINPROPERTY(name, 'HistoryLength') AS 'HistoryLength'
		,LOGINPROPERTY(name, 'IsExpired') AS 'IsExpired'
		,LOGINPROPERTY(name, 'IsLocked') AS 'IsLocked'
		,LOGINPROPERTY(name, 'IsMustChange') AS 'IsMustChange'
		,LOGINPROPERTY(name, 'LockoutTime') AS 'LockoutTime'
		,LOGINPROPERTY(name, 'PasswordHash') AS 'PasswordHash'
		,LOGINPROPERTY(name, 'PasswordLastSetTime') AS 'PasswordLastSetTime'
		,LOGINPROPERTY(name, 'PasswordHashAlgorithm') AS 'PasswordHashAlgorithm'
		,is_expiration_checked
		,create_date
		,modify_date
FROM    sys.sql_logins
WHERE   1 = 1
AND		(name = @name OR @name = '')

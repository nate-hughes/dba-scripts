
SELECT  LOGINPROPERTY(USER_NAME(), 'DaysUntilExpiration') AS DaysUntilExpiration
		,LOGINPROPERTY(USER_NAME(), 'IsExpired') AS IsExpired
		,LOGINPROPERTY(USER_NAME(), 'IsLocked') AS IsLocked;

ALTER LOGIN [user] WITH PASSWORD = 'NewPassword';
GO

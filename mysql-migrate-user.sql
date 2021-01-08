-- Create an account and mark the password as expired so that user has to choose a new one when first connecting
SELECT	CONCAT('CREATE USER ''', user, '''@''', host, ''' IDENTIFIED BY ''', '<TempPwdHere>', ''' PASSWORD EXPIRE;') AS NewUserStmt
		,CONCAT('CREATE USER ''', user, '''@''', host, ''' IDENTIFIED BY ''', '<TempPwdHere>', ''';') AS MigrateUserStmt
FROM	mysql.user
WHERE	user = 'integration-service';

-- Find all privileges and roles granted to an existing account
SHOW GRANTS FOR 'integration-service'@'%';

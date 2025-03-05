DECLARE @Login VARCHAR(128) = 'v-%';

SELECT	name
FROM	sys.server_principals
WHERE	name LIKE @Login;

SELECT  DB_NAME(dbid) as DBName
		,COUNT(dbid) as NumberOfConnections
		,loginame as LoginName
FROM	sys.sysprocesses
WHERE	dbid > 4
AND		loginame LIKE @Login
GROUP BY dbid
		,loginame;

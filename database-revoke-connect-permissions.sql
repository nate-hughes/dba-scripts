USE [?];

SELECT 'REVOKE CONNECT FROM [' + name + '];'
		,'GRANT CONNECT FROM [' + name + '];'
FROM sys.sysusers
WHERE islogin = 1
AND hasdbaccess = 1
AND name <> 'dbo';



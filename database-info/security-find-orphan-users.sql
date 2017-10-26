USE master;
GO

DECLARE @SQL NVARCHAR(MAX);

CREATE TABLE #OrphanUsers (
	DBName sysname
	,UserName sysname
	,UserSID VARBINARY(85)
);

SET @SQL = '
INSERT #OrphanUsers (DBName, UserName, UserSID)
SELECT  DB_NAME() AS DBName
       ,name      AS UserName
       ,sid       AS UserSID
FROM    sys.sysusers
WHERE   issqluser = 1
AND     sid IS NOT NULL
AND     sid <> 0x0
AND     LEN(sid) <= 16
AND     SUSER_SNAME(sid) IS NULL;';


EXEC sys.sp_MSforeachdb @SQL;

SELECT  DBName
       ,UserName
       ,UserSID
FROM    #OrphanUsers
ORDER BY DBName
        ,UserName;

DROP TABLE #OrphanUsers;

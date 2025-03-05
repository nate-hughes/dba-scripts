/**********************************************************************************************

			SERVER ROLE MEMBERSHIP

**********************************************************************************************/

WITH CTE_Role (name,role,type_desc,default_database_name)
as
(
SELECT  PRN.name
       ,srvrole.name AS [role]
       ,PRN.type_desc
	   ,PRN.default_database_name
FROM    sys.server_role_members membership
        INNER JOIN (
                    SELECT  principal_id, name
                    FROM    sys.server_principals
                    WHERE   type_desc = 'SERVER_ROLE'
                   ) srvrole ON srvrole.principal_id = membership.role_principal_id
        RIGHT JOIN sys.server_principals PRN ON PRN.principal_id = membership.member_principal_id
WHERE   PRN.type_desc NOT IN ('SERVER_ROLE')
        AND PRN.is_disabled = 0
UNION ALL
SELECT  p.name
       ,'ControlServer'
       ,p.type_desc AS loginType
	   ,p.default_database_name
FROM    sys.server_principals p
        JOIN sys.server_permissions Sp ON p.principal_id = Sp.grantee_principal_id
WHERE   Sp.class = 100
        AND Sp.type = 'CL'
        AND Sp.state = 'G' 
)
SELECT name,
Type_Desc ,
default_database_name ,
CASE WHEN [public]=1 THEN 'Y' ELSE '' END as 'Public',
CASE WHEN [sysadmin] =1 THEN 'Y' ELSE '' END as 'SysAdmin' ,
CASE WHEN [securityadmin] =1 THEN 'Y' ELSE '' END as 'SecurityAdmin',
CASE WHEN [serveradmin] =1 THEN 'Y' ELSE '' END as 'ServerAdmin',
CASE WHEN [setupadmin] =1 THEN 'Y' ELSE '' END as 'SetupAdmin',
CASE WHEN [processadmin] =1 THEN 'Y' ELSE '' END as 'ProcessAdmin',
CASE WHEN [diskadmin] =1 THEN 'Y' ELSE '' END as 'DiskAdmin',
CASE WHEN [dbcreator] =1 THEN 'Y' ELSE '' END as 'DBCreator',
CASE WHEN [bulkadmin] =1 THEN 'Y' ELSE '' END as 'BulkAdmin' ,
CASE WHEN [ControlServer] =1 THEN 'Y' ELSE '' END as 'ControlServer' 
FROM CTE_Role 
PIVOT
(
 COUNT(role) For role in ([public],[sysadmin],[securityadmin],[serveradmin],[setupadmin],[processadmin],[diskadmin],[dbcreator],[bulkadmin],[ControlServer])
) as pvt
WHERE Type_Desc not in ('SERVER_ROLE','CERTIFICATE_MAPPED_LOGIN')
ORDER BY name,type_desc,default_database_name;
go

--/**********************************************************************************************

--			DATABASE ROLE MEMBERSHIP

--**********************************************************************************************/

--CREATE TABLE #DatabaseRoleMemberShip 
--	(
--		 Username varchar(100),
--		 UserType varchar(100),
--		 Rolename varchar(100),
--		 Databasename varchar(100)
		  
--	 );

--DECLARE @Cmd as varchar(max)
--		,@PivotColumnHeaders VARCHAR(4000);

--SET @Cmd = 'USE [?] ;insert into #DatabaseRoleMemberShip 
--select	u.name,u.type_desc,r.name,''?''
--FROM    sys.database_role_members RM
--        INNER JOIN sys.database_principals U ON U.principal_id = RM.member_principal_id
--        INNER JOIN sys.database_principals R ON R.principal_id = RM.role_principal_id
--		INNER JOIN sys.server_principals S ON S.principal_id = RM.role_principal_id
--where	u.Type != ''R''';

--EXEC sp_MSforeachdb @command1=@cmd;

-- SELECT  @PivotColumnHeaders =                         
--  COALESCE(@PivotColumnHeaders + ',[' + cast(rolename as varchar(max)) + ']','[' + cast(rolename as varchar(max))+ ']'                        
--  )                        
--  FROM (SELECT DISTINCT rolename from #DatabaseRoleMemberShip )a ORDER BY rolename  ASC;

--SET @Cmd = 
--'select 
--databasename,username,UserType ,'+@PivotColumnHeaders+'
--from 
--(
--	select   * from #DatabaseRoleMemberShip) as p
--pivot 
--(
--	count(rolename  )
--for 	rolename in ('+@PivotColumnHeaders+') )as pvt
--order by databasename,username';

--EXECUTE(@Cmd );

--DROP TABLE #DatabaseRoleMemberShip; 
--GO


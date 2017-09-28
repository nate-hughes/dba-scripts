SET NOCOUNT ON;

DECLARE @Login NVARCHAR(128)
		, @ModDate DATETIME
		, @Database NVARCHAR(128)
		, @SQL NVARCHAR(MAX);

--SET @Login = 'applogin';
--SET @ModDate = '7/21/2016';
SET @Database = 'rp_util';

----- SERVER LOGINS -----
IF @Database IS NULL
	SELECT	[ServerLogin] = sp.name
			, [LoginType] = sp.type_desc
			, [ServerRole] = STUFF((
								SELECT	',' + sp2.name
								FROM	master.sys.server_role_members rm
										INNER JOIN master.sys.server_principals sp2 ON rm.role_principal_id = sp2.principal_id
								WHERE	sp.principal_id = rm.member_principal_id
								FOR XML PATH(''),TYPE).value('.','VARCHAR(MAX)'),1,1,'')
			, [DefaultDB] = sp.default_database_name
			, [LastModified] = sp.modify_date
	FROM	master.sys.server_principals sp
	WHERE	sp.is_disabled = 0
	AND		sp.name = ISNULL(@Login, sp.name)
	AND		sp.modify_date >= ISNULL(@ModDate,sp.modify_date)
	ORDER BY sp.name;

----- DATABASE PERMISSIONS -----
IF EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE object_id = OBJECT_ID(N'[tempdb].[dbo].[#DB]') AND type in (N'U'))
	DROP TABLE [tempdb].[dbo].[#DB];

CREATE TABLE #DB (
	[Database] NVARCHAR(128)
	, [PermissionState] NVARCHAR(60)
	, [Permission] NVARCHAR(128)
	, [Object] NVARCHAR(128)
	, [Login] NVARCHAR(128)
	, LoginType NVARCHAR(60)
	, [LastModified] DATETIME
);

SET @SQL = 'USE [?];
INSERT INTO #DB (
	[Database]
	, [PermissionState]
	, [Permission]
	, [Object]
	, [Login]
	, LoginType
	, [LastModified]
)
SELECT	[Database] = DB_NAME()
		, [PermissionState] = p.state_desc
		, [Permission] = p.permission_name
		, [Object] = CASE WHEN p.class = 0 THEN ''DB: '' + DB_NAME(p.major_id)
				WHEN p.class = 3 THEN ''Schema: '' + s.name
				ELSE ''Object: '' + OBJECT_NAME(p.major_id)
			END
		, [Login] = dp.name
		, LoginType = dp.type_desc
		, [LastModified] = dp.modify_date
FROM	sys.database_principals dp
		INNER JOIN sys.database_permissions p ON dp.principal_id = p.grantee_principal_id
		LEFT OUTER JOIN sys.objects so ON p.major_id = so.object_id AND p.class = 1
		LEFT OUTER JOIN sys.schemas s ON p.major_id = s.schema_id AND p.class = 3
WHERE	dp.name = ISNULL(' + CASE WHEN @Login IS NOT NULL THEN '''' + @Login + '''' ELSE 'NULL' END + ', dp.name)
AND		dp.modify_date >= ISNULL(' + CASE WHEN @ModDate IS NOT NULL THEN '''' + CONVERT(VARCHAR,@ModDate) + '''' ELSE 'NULL' END + ',dp.modify_date);';

EXECUTE sp_MSforeachdb @SQL;

SELECT	[Database]
		, [PermissionState]
		, [Permission]
		, [Object]
		, [Login]
		, LoginType
		, [LastModified]
FROM	#DB
WHERE	[Database] = ISNULL(@Database, [Database])
AND		[Login] != 'public'
ORDER BY [Database]
		, [Login]
		, [Object];

----- ROLE MEMBERS -----
IF EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE object_id = OBJECT_ID(N'[tempdb].[dbo].[#RM]') AND type in (N'U'))
	DROP TABLE [tempdb].[dbo].[#RM];

CREATE TABLE #RM (
	[Database] NVARCHAR(128)
	, [Role] NVARCHAR(128)
	, [Login] NVARCHAR(512)
	, [LastModified] DATETIME
);

SET @SQL = 'USE [?];
SET QUOTED_IDENTIFIER ON;
INSERT INTO #RM (
	[Database]
	, [Role]
	, [Login]
	, [LastModified]
)
SELECT	[Database] = DB_NAME()
		, [Role]
		, [Login]
		, [LastModified]
FROM	(
			SELECT	[Role] = sp.name
					, [Login] = STUFF((
								SELECT	'','' + sp2.name
								FROM	sys.database_role_members rm
										INNER JOIN sys.database_principals sp2 ON rm.member_principal_id = sp2.principal_id
								WHERE	rm.role_principal_id = sp.principal_id
								AND		sp2.name = ISNULL(' + CASE WHEN @Login IS NOT NULL THEN '''' + @Login + '''' ELSE 'NULL' END + ', sp2.name)
								AND		sp2.modify_date >= ISNULL(' + CASE WHEN @ModDate IS NOT NULL THEN '''' + CONVERT(VARCHAR,@ModDate) + '''' ELSE 'NULL' END + ', sp2.modify_date)
								ORDER BY sp2.name
								FOR XML PATH(''''),TYPE).value(''.'',''VARCHAR(MAX)''),1,1,'''')
					, [LastModified] = sp.modify_date
			FROM	sys.database_principals sp
			WHERE	sp.type IN (''R'',''A'') --DATABASE_ROLE,APPLICATION_ROLE
		) x
WHERE	x.[Login] IS NOT NULL;';

EXECUTE sp_MSforeachdb @SQL;

SELECT	[Database]
	, [Role]
	, [Login]
	, [LastModified]
FROM	#RM
WHERE	[Database] = ISNULL(@Database, [Database])
ORDER BY [Database]
		, [Role]
		, [Login];

----- ORPHAN USERS -----
IF EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE object_id = OBJECT_ID(N'[tempdb].[dbo].[#OU]') AND type in (N'U'))
	DROP TABLE [tempdb].[dbo].[#OU];
	
CREATE TABLE #OU (
	[Database] NVARCHAR(128)
	, [Login] NVARCHAR(128)
	, [LastModified] DATETIME
);

SET @SQL = 'USE [?];
SET QUOTED_IDENTIFIER ON;
INSERT INTO #OU (
	[Database]
	, [Login]
	, [LastModified]
)
SELECT	[Database] = DB_NAME()
		, d.name
		, d.modify_date
FROM	sys.database_principals d
		LEFT OUTER JOIN sys.server_principals s
			ON d.sid = s.sid
WHERE	s.sid IS NULL
AND		d.type IN (''U'', ''S'') -- WINDOWS_USER, SQL_USER
AND		d.name NOT IN (''guest'', ''INFORMATION_SCHEMA'', ''sys'');'

EXECUTE sp_MSforeachdb @SQL;

SELECT	[Database]
	, [Login]
	, [LastModified]
FROM	#OU
WHERE	[Database] = ISNULL(@Database, [Database])
ORDER BY [Database]
		, [Login];


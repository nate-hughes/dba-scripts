DECLARE	@sql VARCHAR(2048)
		,@sort INT
		,@login VARCHAR(128) = NULL;

DECLARE tmp CURSOR FOR

/*********************************************/
/*********   DB CONTEXT STATEMENT    *********/
/*********************************************/
SELECT	'-- [-- DB CONTEXT --] --' AS [-- SQL STATEMENTS --]
		,1 AS [-- RESULT ORDER HOLDER --]
UNION ALL
SELECT	'USE' + SPACE(1) + QUOTENAME(DB_NAME()) + ';' AS [-- SQL STATEMENTS --]
		,1 AS [-- RESULT ORDER HOLDER --]
UNION ALL
SELECT	'' AS [-- SQL STATEMENTS --]
		,2 AS [-- RESULT ORDER HOLDER --]
UNION ALL

/*********************************************/
/*********     DB USER CREATION      *********/
/*********************************************/
SELECT	'-- [-- DB USERS --] --' AS [-- SQL STATEMENTS --]
		,3 AS [-- RESULT ORDER HOLDER --]
UNION ALL
SELECT  'IF NOT EXISTS (SELECT [name] FROM sys.database_principals WHERE [name] =' + SPACE(1) + '''' + [name] + '''' + ') BEGIN CREATE USER ' + SPACE(1) + QUOTENAME([name]) + ' FOR LOGIN ' + QUOTENAME([name]) + ' WITH DEFAULT_SCHEMA = ' + QUOTENAME([default_schema_name]) + SPACE(1) + 'END;' AS [-- SQL STATEMENTS --]
		,3 AS [-- RESULT ORDER HOLDER --]
FROM    sys.database_principals
WHERE	[type] IN ('U', 'S', 'G') -- windows users, sql users, windows groups
AND		[principal_id] > 4 -- 0 to 4 are system users/schemas
AND		(@login IS NULL OR [name] = @login)
UNION ALL
SELECT	'' AS [-- SQL STATEMENTS --]
		,4 AS [-- RESULT ORDER HOLDER --]
UNION ALL

/*********************************************/
/*********    DB ROLE PERMISSIONS    *********/
/*********************************************/
SELECT	'-- [-- DB ROLES --] --' AS [-- SQL STATEMENTS --]
		,5 AS [-- RESULT ORDER HOLDER --]
UNION ALL
SELECT	'ALTER ROLE ' + QUOTENAME(USER_NAME(rm.[role_principal_id])) + ' ADD MEMBER ' + QUOTENAME(USER_NAME(rm.[member_principal_id])) + ';' AS [-- SQL STATEMENTS --]
		,6 AS [-- RESULT ORDER HOLDER --]
FROM	sys.database_role_members AS rm
WHERE   USER_NAME(rm.[member_principal_id]) IN (  
			--get user names on the database
			SELECT [name]
			FROM	sys.database_principals
			WHERE	[principal_id] > 4 -- 0 to 4 are system users/schemas
			AND		[type] IN ('G', 'S', 'U') -- S = SQL user, U = Windows user, G = Windows group
		)
AND		(@login IS NULL OR USER_NAME(rm.[member_principal_id]) = @login)
UNION ALL
SELECT	'' AS [-- SQL STATEMENTS --]
		,7 AS [-- RESULT ORDER HOLDER --]
UNION ALL

/*********************************************/
/*********  OBJECT LEVEL PERMISSIONS *********/
/*********************************************/
SELECT	'-- [-- OBJECT LEVEL PERMISSIONS --] --' AS [-- SQL STATEMENTS --]
		,8 AS [-- RESULT ORDER HOLDER --]
UNION ALL
SELECT	CASE 
			WHEN p.[state] <> 'W' THEN p.[state_desc] 
			ELSE 'GRANT'
		END
        + SPACE(1) + p.[permission_name] + SPACE(1) + 'ON ' + QUOTENAME(SCHEMA_NAME(o.[schema_id])) + '.' + QUOTENAME(o.[name]) --select, execute, etc on specific objects
		+ CASE
			WHEN c.[column_id] IS NULL THEN SPACE(0)
			ELSE '(' + QUOTENAME(c.[name]) + ')'
		END
        + SPACE(1) + 'TO' + SPACE(1) + QUOTENAME(USER_NAME(dp.[principal_id])) COLLATE DATABASE_DEFAULT
		+ CASE 
			WHEN p.[state] <> 'W' THEN SPACE(0)
			ELSE SPACE(1) + 'WITH GRANT OPTION'
		END
		+ ';' AS [-- SQL STATEMENTS --]
		,9 AS [-- RESULT ORDER HOLDER --]
FROM	sys.database_permissions p
        JOIN sys.objects o ON p.[major_id] = o.[object_id]
        JOIN sys.database_principals dp ON p.[grantee_principal_id] = dp.[principal_id]
        LEFT JOIN sys.columns c ON c.[column_id] = p.[minor_id] AND c.[object_id] = p.[major_id]
WHERE	dp.[type] IN ('U', 'S', 'G') -- windows users, sql users, windows groups
AND		dp.[principal_id] > 4 -- 0 to 4 are system users/schemas
AND		(@login IS NULL OR dp.[name] = @login)
UNION ALL
SELECT	'' AS [-- SQL STATEMENTS --]
		,10 AS [-- RESULT ORDER HOLDER --]
UNION ALL

/*********************************************/
/*********    DB LEVEL PERMISSIONS   *********/
/*********************************************/
SELECT	'-- [--DB LEVEL PERMISSIONS --] --' AS [-- SQL STATEMENTS --]
		,11 AS [-- RESULT ORDER HOLDER --]
UNION ALL
SELECT	CASE 
			WHEN p.[state] <> 'W' THEN p.[state_desc] --W=Grant With Grant Option
			ELSE 'GRANT'
		END
		+ SPACE(1) + p.[permission_name]
		+ SPACE(1) + 'TO' + SPACE(1) + '[' + USER_NAME(dp.[principal_id]) + ']' COLLATE DATABASE_DEFAULT
		+ CASE 
			WHEN p.[state] <> 'W' THEN SPACE(0) 
			ELSE SPACE(1) + 'WITH GRANT OPTION' 
		END
		+ ';' AS [-- SQL STATEMENTS --]
		,12 AS [-- RESULT ORDER HOLDER --]
FROM	sys.database_permissions p
		JOIN sys.database_principals dp ON p.[grantee_principal_id] = dp.[principal_id]
WHERE   p.[major_id] = 0 -- 0 = The database itself
AND		dp.[principal_id] > 4 -- 0 to 4 are system users/schemas
AND		dp.[type] IN ('G', 'S', 'U') -- S = SQL user, U = Windows user, G = Windows group
AND		(@login IS NULL OR dp.[name] = @login)
UNION ALL
SELECT	'' AS [-- SQL STATEMENTS --]
		,13 AS [-- RESULT ORDER HOLDER --]
UNION ALL

/*************************************************/
/*********    SCHEMA LEVEL PERMISSIONS   *********/
/*************************************************/
SELECT	'-- [--DB LEVEL SCHEMA PERMISSIONS --] --' AS [-- SQL STATEMENTS --]
		,14 AS [-- RESULT ORDER HOLDER --]
UNION ALL
SELECT	CASE
			WHEN p.[state] <> 'W' THEN p.[state_desc]
			ELSE 'GRANT'
		END
		+ SPACE(1) + p.[permission_name]
		+ SPACE(1) + 'ON' + SPACE(1) + p.[class_desc] + '::' COLLATE DATABASE_DEFAULT
		+ QUOTENAME(SCHEMA_NAME(p.[major_id]))
		+ SPACE(1) + 'TO' + SPACE(1) + QUOTENAME(USER_NAME(p.[grantee_principal_id])) COLLATE DATABASE_DEFAULT
		+ CASE
			WHEN p.[state] <> 'W' THEN SPACE(0)
			ELSE SPACE(1) + 'WITH GRANT OPTION'
		END
		+ ';' AS [-- SQL STATEMENTS --]
		,15 AS [-- RESULT ORDER HOLDER --]
FROM	sys.database_permissions p
		JOIN sys.schemas s ON p.[major_id] = s.[schema_id]
		JOIN sys.database_principals dp ON p.[grantee_principal_id] = dp.[principal_id]
WHERE	p.[class] = 3 -- class 3 = schema
AND		(@login IS NULL OR dp.[name] = @login)
ORDER BY [-- RESULT ORDER HOLDER --];


OPEN tmp;

FETCH NEXT FROM tmp INTO @sql, @sort;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT @sql;
    FETCH NEXT FROM tmp INTO @sql, @sort;
END;

CLOSE tmp;
DEALLOCATE tmp;

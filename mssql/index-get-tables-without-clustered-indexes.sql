DECLARE @l_SQL NVARCHAR(MAX)
		, @l_DBName NVARCHAR(128);

-- comment out SET if you want to check against ALL databases
SET @l_DBName = 'DBName';

CREATE TABLE #DB_FILE_INFO (
	DBName NVARCHAR(128)
	, TblName NVARCHAR(128)
);

SET @l_SQL = 'USE [?];
			INSERT INTO #DB_FILE_INFO (DBName, TblName)
			SELECT  DB_NAME()
					, o.name
			FROM sys.objects o
			WHERE o.type=''U''
			AND NOT EXISTS(SELECT 1 FROM sys.indexes i
							WHERE o.object_id = i.object_id
							AND i.type_desc = ''CLUSTERED'')
			ORDER BY 1';

EXEC sp_msforeachdb @l_SQL;

IF @l_DBName IS NOT NULL
	DELETE	
	FROM	#DB_FILE_INFO
	WHERE	DBName <> @l_DBName
	OR		TblName = 'dtproperties';
ELSE
	-- remove system databases
	DELETE
	FROM	#DB_FILE_INFO
	WHERE	DBName IN ('master', 'model', 'msdb', 'tempdb', 'reportserver', 'reportservertempdb')
	OR		TblName = 'dtproperties'

SELECT	*
FROM	#DB_FILE_INFO;

DROP TABLE #DB_FILE_INFO;
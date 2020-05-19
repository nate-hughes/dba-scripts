USE master;
GO

IF EXISTS (
	SELECT	1 
	FROM	tempdb.sys.objects
	WHERE	[type] = 'U'
	AND		[object_id] = OBJECT_ID(N'tempdb..#DB_FILE_INFO')
)
	DROP TABLE #DB_FILE_INFO;

SET NOCOUNT ON;

CREATE TABLE #DB_FILE_INFO (
	DBName NVARCHAR(128)
	, FileGroupName NVARCHAR(128)
	, [Size] BIGINT
	, Used BIGINT
	, [type] TINYINT
	, FileId INT
	, physical_name NVARCHAR(260)
);

DECLARE @l_sql NVARCHAR(4000);

SET @l_sql =
'USE [?];
IF DB_NAME() <> N''?'' GOTO Error_Exit;

INSERT INTO #DB_FILE_INFO (
	DBName
	, FileGroupName
	, [Size]
	, Used
	, [type]
	, FileId
	, physical_name
)
SELECT	DB_NAME()
		, FileGroupName = CASE WHEN f.data_space_id = 0 THEN ''LOG''
								ELSE s.name
							END
		, [Size] = CONVERT(BIGINT, f.size) * 8 / 1024 -- MB
		, Used = CONVERT(BIGINT, FILEPROPERTY(f.name, ''SpaceUsed'')) * 8 / 1024 -- MB
		, [type] = f.[type]
		, FileId = f.[file_id]
		, f.physical_name
FROM	sys.database_files f
		LEFT OUTER JOIN sys.data_spaces s
			ON f.data_space_id = s.data_space_id;

Error_Exit:

';

EXEC sp_msforeachdb @l_sql;

SELECT	DBName
		, FileGroupName
		, FileSize = [Size]
		, FileSizeUsed = Used
		, FileSizeUsedPct = CONVERT(NUMERIC(4,1), Used * 1.0 / [Size] * 100)
		, FileSizeUnused = [Size] - Used
		, FileSizeUnusedPct = CONVERT(NUMERIC(4,1), ([Size] - Used) * 1.0 / [Size] * 100)
		, physical_name
FROM	#DB_FILE_INFO
ORDER BY DBName
		, [type]
		, FileId;


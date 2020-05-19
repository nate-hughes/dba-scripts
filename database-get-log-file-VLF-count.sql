IF EXISTS (
	SELECT	1 
	FROM	tempdb.sys.objects
	WHERE	[type] = 'U'
	AND		[object_id] = OBJECT_ID(N'tempdb..#LogInfo')
)
	DROP TABLE #LogInfo;
	
DECLARE @l_sql NVARCHAR(4000);

CREATE TABLE #LogInfo (
	DatabaseName NVARCHAR(128) DEFAULT DB_NAME()
	, RecoveryUnitId INT
	, FileId INT
	, FileSize BIGINT
	, StartOffset BIGINT
	, FSeqNo INT
	, [Status] TINYINT
	, Parity TINYINT
	, CreateLSN NUMERIC(25,0)
);

SET @l_sql = 
'USE [?];
INSERT INTO #LogInfo (
	RecoveryUnitId
	, FileId
	, FileSize
	, StartOffset
	, FSeqNo
	, Status
	, Parity
	, CreateLSN
)
EXEC(''DBCC LOGINFO'')';

EXEC sp_msforeachdb @l_sql;

SELECT	DBName = DatabaseName
		, VLFs = COUNT(FileId)
FROM	#LogInfo
GROUP BY DatabaseName
ORDER BY DatabaseName;
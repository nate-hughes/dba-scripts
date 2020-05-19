SET NOCOUNT ON;

DECLARE @l_Table VARCHAR(256);

--\/\/\/ comment out to do ALL tables in db \/\/\/--
SET @l_Table = 'TblName';
 
DECLARE @printOnly  BIT = 0 -- change to 1 if you don't want to execute, just print commands
    , @tableName    VARCHAR(256)
    , @schemaName   VARCHAR(100)
    , @sqlStatement NVARCHAR(1000)
    , @tableCount   INT
    , @statusMsg    VARCHAR(1000)
    , @indexid		INT
    , @compressiontype CHAR(4);
 
IF EXISTS(SELECT * FROM tempdb.sys.tables WHERE name LIKE '%#tables%')
    DROP TABLE #tables; 
 
CREATE TABLE #tables
(
      database_name     sysname
    , schemaName        sysname NULL
    , tableName         sysname NULL
    , processed         bit
    , reads				bigint
    , writes			bigint
    , index_id			int
    , indexname			sysname NULL
    , compressiontype AS CASE WHEN writes = 0 THEN 'PAGE'
							WHEN (reads + writes) * .1 / writes < .1 THEN 'PAGE'
							WHEN (reads + writes) * .1 / writes < .2 THEN 'ROW'
						END 
);
 
IF EXISTS(SELECT * FROM tempdb.sys.tables WHERE name LIKE '%#compression%')
    DROP TABLE #compressionResults;
 
IF NOT EXISTS(SELECT * FROM tempdb.sys.tables WHERE name LIKE '%#compression%')
BEGIN 
 
    CREATE TABLE #compressionResults
    (
          objectName                    varchar(100)
        , schemaName                    varchar(50)
        , index_id                      int
        , partition_number              int
        , size_current_compression      bigint
        , size_requested_compression    bigint
        , sample_current_compression    bigint
        , sample_requested_compression  bigint
    );
 
END;

IF @l_Table IS NULL 
	INSERT INTO #tables
	SELECT DB_NAME()
		, SCHEMA_NAME(t.[schema_id])
		, t.name
		, 0 -- unprocessed
		, ISNULL(SUM(s.user_seeks + s.user_scans + s.user_lookups),0)
		, ISNULL(SUM(s.user_updates),0)
		, i.index_id
		, i.name
	FROM sys.tables t
		INNER JOIN sys.indexes i ON t.[object_id] = i.[object_id]
		INNER JOIN sys.dm_db_index_usage_stats s WITH (NOLOCK) ON i.[object_id] = s.[object_id] AND i.index_id = s.index_id
	GROUP BY t.[schema_id]
			, t.name
			, i.index_id
			, i.name;
ELSE
	INSERT INTO #tables
	SELECT DB_NAME()
		, SCHEMA_NAME(t.[schema_id])
		, t.name
		, 0 -- unprocessed
		, ISNULL(SUM(s.user_seeks + s.user_scans + s.user_lookups),0)
		, ISNULL(SUM(s.user_updates),0)
		, i.index_id
		, i.name
	FROM sys.tables t
		INNER JOIN sys.indexes i ON t.[object_id] = i.[object_id]
		LEFT OUTER JOIN sys.dm_db_index_usage_stats s WITH (NOLOCK) ON i.[object_id] = s.[object_id] AND i.index_id = s.index_id
	WHERE	t.name = @l_Table
	GROUP BY t.[schema_id]
			, t.name
			, i.index_id
			, i.name;
 
DELETE FROM #tables WHERE compressiontype IS NULL;

SELECT @tableCount = COUNT(*) FROM #tables;
 
WHILE EXISTS(SELECT * FROM #tables WHERE processed = 0)
BEGIN
 
    SELECT TOP 1 @tableName = tableName
        , @schemaName = schemaName
        , @indexid = index_id
        , @compressiontype = compressiontype
    FROM #tables WHERE processed = 0;
 
    SELECT @statusMsg = 'Working on ' + CAST(((@tableCount - COUNT(*)) + 1) AS VARCHAR(10)) 
        + ' of ' + CAST(@tableCount AS VARCHAR(10))
    FROM #tables
    WHERE processed = 0;
 
    RAISERROR(@statusMsg, 0, 42) WITH NOWAIT;
 
    SET @sqlStatement = 'EXECUTE sp_estimate_data_compression_savings ''' 
                        + @schemaName + ''', ''' + @tableName + ''', ''' + CONVERT(VARCHAR,@indexid) + ''', NULL, ''' + @compressiontype + ''';' -- ROW, PAGE, or NONE
 
    IF @printOnly = 1
    BEGIN 
 
        SELECT @sqlStatement;
 
    END
    ELSE
    BEGIN
 
        INSERT INTO #compressionResults
        EXECUTE sp_executesql @sqlStatement;
 
    END;
 
    UPDATE #tables
    SET processed = 1
    WHERE tableName = @tableName
        AND schemaName = @schemaName
        AND @indexid = index_id;
 
END;

--SELECT * FROM #compressionResults;

SELECT r.objectName
		, t.indexname 
		, t.compressiontype
		, r.size_current_compression / 1024.0 AS size_current_compression_MB
		, r.size_requested_compression / 1024.0 AS size_requested_compression_MB
		, reclaimed_MB = (r.size_current_compression-r.size_requested_compression) / 1024.0
		, t.reads
		, t.writes
		, CASE WHEN t.index_id < 2 THEN 'ALTER TABLE ' + '[' + t.schemaName + ']'+'.' + '[' + t.tableName + ']' + ' REBUILD WITH (DATA_COMPRESSION='+compressiontype+');'
				ELSE 'ALTER INDEX '+ '[' + t.indexname + ']' + ' ON ' + '[' + t.schemaName + ']' + '.' + '[' + t.tableName + ']' + ' REBUILD WITH (DATA_COMPRESSION='+compressiontype+');'
			END
FROM #compressionResults r
	INNER JOIN #tables t
		ON r.objectName = t.tableName
		AND r.index_id = t.index_id
WHERE	r.size_current_compression > r.size_requested_compression
ORDER BY r.objectName
		, t.index_id;
    
    
    
    

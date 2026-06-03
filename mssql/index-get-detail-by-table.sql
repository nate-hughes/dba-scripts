/*
Purpose:
    Review index metadata, usage, possible missing indexes, and possible low-value indexes
    for a single table in the current database.

Inputs:
    @TblName: two-part table name to review, formatted as schema.table.
    @MinFragmentation: minimum fragmentation percentage intended for physical-stats filtering.
    @MinPageCount: minimum page count intended for physical-stats filtering.
    @ShowIndexSize: when enabled, runs Index Size / Physical Stats block.
    @EstimateCompression: when enabled, runs sys.sp_estimate_data_compression_savings.
        This can be blocking/resource-intensive and should be used intentionally.
    @CompressionType: compression type used by sys.sp_estimate_data_compression_savings.
        Common values: ROW or PAGE

Notes:
    - Index usage and missing-index DMV data are since the last SQL Server restart, database
      attach, or relevant metadata reset.
    - Output should be treated as review candidates, not automatic change scripts.
    - Drop/rebuild statements should be validated against workload, constraints, foreign keys,
      and execution plans before use.
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET LOCK_TIMEOUT 5000;
GO

DECLARE @DBId                INT          = DB_ID()
       ,@SchemaName          SYSNAME
       ,@TblName             SYSNAME      = N'schema.table'
       ,@TblId               INT
       ,@MinFragmentation    REAL         = 5.0 -- Defaulted to 5% as recommended by MS in BOL
       ,@MinPageCount        INT          = 1000 -- Defaulted to 1000 pages as recommended by MS in BOL
       ,@ShowIndexSize       BIT          = 0 -- Enables sys.dm_db_index_physical_stats - may be slower or encounter blocking on busy systems
       ,@EstimateCompression BIT          = 0 -- Leave off unless specifically looking for compression estimates
       ,@CompressionType     NVARCHAR(60) = N'ROW'
       ,@SQLServerStartTime  DATETIME;

SET @TblId = OBJECT_ID(@TblName);
SET @SchemaName = OBJECT_SCHEMA_NAME(@TblId, @DBId);
SELECT @SQLServerStartTime = sqlserver_start_time FROM sys.dm_os_sys_info;

-- fail fast if the table name does not resolve.
IF @TblId IS NULL
BEGIN
    RAISERROR('Table not found. Confirm @TblName is a valid two-part name in the current database.', 16, 1);
    RETURN;
END;

/****** CONTEXT BLOCK START ******/
SELECT 'CONTEXT:' AS Info;

SELECT DB_NAME() AS DBName
    ,@SchemaName AS SchName
    ,OBJECT_NAME(@TblId, @DBId) AS TblName
    ,@SQLServerStartTime AS SQLSrvrStartTime
    ,@MinFragmentation AS MinFragmentation
    ,@MinPageCount AS MinPageCount
    ,@EstimateCompression AS EstCompression
    ,@CompressionType AS CompressionType;
/****** CONTEXT BLOCK END ******/

/****** INDEX CATALOG BLOCK START ******/
SELECT  'CATALOG:' AS Info;
SELECT  '[' + DB_NAME() + '].[' + @SchemaName + '].[' + OBJECT_NAME(@TblId, @DBId) + ']' AS [Object]
       ,i.name                                                                           AS [Index]
       ,i.type_desc                                                                      AS IndexType
       ,ds.type_desc                                                                     AS DataSpaceType
       ,ds.name                                                                          AS DataSpaceName
       ,i.is_primary_key                                                                 AS PK
       ,i.is_unique_constraint                                                           AS AK
       ,i.is_unique                                                                      AS IsUnique
       ,i.has_filter                                                                     AS HasFilter
       ,i.filter_definition                                                              AS FilterDef
       ,i.fill_factor                                                                    AS [FillFactor]
       ,STUFF((
            SELECT    CASE WHEN ic.is_descending_key = 1 THEN ', ' + c.name + '(-)'
                            ELSE ', ' + c.name
                    END
            FROM  sys.index_columns      ic
                INNER JOIN sys.columns c
                    ON  c.object_id = i.object_id
                    AND c.column_id = ic.column_id
            WHERE ic.object_id = @TblId
            AND   ic.index_id = i.index_id
            AND   ic.is_included_column = 0
            ORDER BY ic.key_ordinal
            FOR XML PATH('')
        ), 1, 2, ''
        )                                                                                AS KeyColumns
       ,STUFF((
            SELECT    CASE WHEN ic.is_descending_key = 1 THEN ', ' + c.name + '(-)'
                            ELSE ', ' + c.name
                    END
            FROM  sys.index_columns      ic
                INNER JOIN sys.columns c
                    ON  c.object_id = i.object_id
                    AND c.column_id = ic.column_id
            WHERE ic.object_id = @TblId
            AND   ic.index_id = i.index_id
            AND   ic.is_included_column = 1
            ORDER BY ic.key_ordinal
            FOR XML PATH('')
        ), 1, 2, ''
        )                                                                                AS IncludedColumns
       ,ISNULL(s.user_seeks + s.user_scans + s.user_lookups,0)                           AS TotalReads
       ,ISNULL(s.user_updates,0)                                                         AS TotalWrites
       ,(SELECT MAX(v.LastRead)
         FROM (
                VALUES (s.last_user_seek),(s.last_user_scan),(s.last_user_lookup)
              ) v(LastRead)
        )                                                                                AS LastRead
       ,s.last_user_update                                                               AS LastWrite
FROM    sys.indexes                            i
        INNER JOIN sys.data_spaces             ds
            ON i.data_space_id = ds.data_space_id
        LEFT JOIN sys.dm_db_index_usage_stats AS s
            ON  s.object_id = i.object_id
            AND i.index_id = s.index_id
            AND s.database_id = @DBId
WHERE   i.object_id = @TblId
AND     i.is_disabled = 0
AND     i.is_hypothetical = 0
ORDER BY i.index_id
		,i.name
OPTION (MAXDOP 2);
/****** INDEX CATALOG BLOCK END ******/

/****** INDEX SIZE BLOCK START ******/
IF @ShowIndexSize = 1
BEGIN
    DECLARE @tmp_compression TABLE (
        object_name                                    NVARCHAR(128)
       ,schema_name                                    NVARCHAR(128)
       ,index_id                                       INT          PRIMARY KEY CLUSTERED
       ,partition_number                               INT
       ,size_with_current_compression_setting          BIGINT
       ,size_with_requested_compression_setting        BIGINT
       ,sample_size_with_current_compression_setting   BIGINT
       ,sample_size_with_requested_compression_setting BIGINT
    );

    IF @EstimateCompression = 1
    BEGIN
        SET @TblName = OBJECT_NAME(@TblId, @DBId);

        INSERT INTO @tmp_compression (
            object_name
		    ,schema_name
		    ,index_id
		    ,partition_number
		    ,size_with_current_compression_setting
		    ,size_with_requested_compression_setting
		    ,sample_size_with_current_compression_setting
		    ,sample_size_with_requested_compression_setting
        )
        EXEC sys.sp_estimate_data_compression_savings
		    @schema_name = @SchemaName
		    ,@object_name = @TblName
		    ,@index_id = NULL
		    ,@partition_number = NULL
		    ,@data_compression = @CompressionType;
    END;

    SELECT  'SIZE:' AS Info;

    SELECT  '[' + DB_NAME() + '].[' + OBJECT_SCHEMA_NAME(@TblId, @DBId) + '].[' + OBJECT_NAME(@TblId, @DBId) + ']' AS [Object]
           ,i.name                                                                                                 AS [Index]
           ,i.type_desc                                                                                            AS IndexType
	         ,ps.alloc_unit_type_desc                                                                                AS AllocationType
           ,CONVERT(NUMERIC(9, 2), ps.page_count * 8 * /*convert to MB*/ 0.000976562)                              AS IndexSizeMB
           ,ps.page_count                                                                                          AS Pages
           ,CONVERT(NUMERIC(5, 2), ps.avg_fragmentation_in_percent)                                                AS [Fragmentation%]
           ,CONVERT(NUMERIC(5, 2), ps.avg_page_space_used_in_percent)                                              AS [AvgPageSpaceUsed%]
           ,ps.record_count                                                                                        AS Records
           ,ps.avg_record_size_in_bytes                                                                            AS AvgRecordSizeBytes
           ,ps.compressed_page_count                                                                               AS CompressedPages
           ,CONVERT(NUMERIC(5, 2), tmp.size_with_requested_compression_setting * /*convert to MB*/ 0.000976562)    AS EstCompressedSizeMB
           ,'ALTER INDEX [' + i.name + +'] ON ' + '[' + OBJECT_SCHEMA_NAME(@TblId, @DBId) + '].['
            + OBJECT_NAME(@TblId, @DBId) + ']' + ' REBUILD WITH ( FILLFACTOR = '
            + CONVERT(   CHAR(3), CASE WHEN i.fill_factor = 0 THEN 100
                                       ELSE i.fill_factor
                                  END
                     ) + ', ONLINE=ON, SORT_IN_TEMPDB=ON );' + ' UPDATE STATISTICS [' + OBJECT_SCHEMA_NAME(@TblId, @DBId)
            + '].[' + OBJECT_NAME(@TblId, @DBId) + '] [' + i.name + +'];'                                          AS RebuildScript
    FROM    sys.dm_db_index_physical_stats(@DBId, @TblId, NULL, NULL, 'LIMITED') AS ps
            INNER JOIN sys.indexes i
                ON  ps.object_id = i.object_id
                AND ps.index_id = i.index_id
            LEFT OUTER JOIN @tmp_compression tmp
                ON i.index_id = tmp.index_id
    WHERE   i.object_id = @TblId
    AND     i.is_disabled = 0
    AND     i.is_hypothetical = 0
    AND     ps.page_count >= @MinPageCount
    AND     ps.avg_fragmentation_in_percent >= @MinFragmentation
    ORDER BY i.index_id
            ,i.name
    OPTION (MAXDOP 2);
END;
/****** INDEX SIZE BLOCK END ******/

/****** POSSIBLE MISSING INDEXES BLOCK START ******/
SELECT  'POSSIBLE MISSING INDEXES SINCE LAST RESTART:' AS Info;

WITH MissingIndexBase AS (
    SELECT mid.index_handle
        ,mig.index_group_handle
        ,migs.group_handle
        ,mid.database_id
        ,mid.object_id
        ,mid.statement AS FullObjectName
        ,mid.equality_columns AS EqualityColumns
        ,mid.inequality_columns AS InequalityColumns
        ,mid.included_columns AS IncludedColumns
        ,migs.unique_compiles AS UniqueCompiles
        ,migs.user_seeks AS UserSeeks
        ,migs.user_scans AS UserScans
        ,migs.last_user_seek AS LastUserSeek
        ,migs.last_user_scan AS LastUserScan
        ,migs.avg_total_user_cost AS AvgTotalUserCost
        ,migs.avg_user_impact AS AvgUserImpact
        ,CONVERT(NUMERIC(19, 2), (migs.avg_total_user_cost * (migs.avg_user_impact / 100.0)) * (migs.user_seeks + migs.user_scans)) AS EstimatedImpact
    FROM sys.dm_db_missing_index_group_stats migs
        INNER JOIN sys.dm_db_missing_index_groups mig
            ON migs.group_handle = mig.index_group_handle
        INNER JOIN sys.dm_db_missing_index_details mid
            ON mig.index_handle = mid.index_handle
    WHERE mid.database_id = @DBId
    AND mid.object_id = @TblId
)
,MissingIndexRanked AS (
    SELECT mib.*
        ,ROW_NUMBER() OVER (
            ORDER BY mib.EstimatedImpact DESC
                    ,mib.UserSeeks + mib.UserScans DESC
                    ,mib.LastUserSeek DESC
        ) AS ImpactRank
    FROM MissingIndexBase mib
)
SELECT mir.EstimatedImpact AS Impact
    --,mir.ImpactRank
    ,mir.FullObjectName AS TblName
    ,mir.EqualityColumns AS EqualityCols
    ,mir.InequalityColumns AS InequalityCols
    ,mir.IncludedColumns AS IncludedCols
    ,mir.UserSeeks AS RecIndxSeeks -- number of times SQL Server thought this missing index could have helped a seek-style operation
    ,mir.UserScans AS RecIndxScans -- number of times SQL Server thought this missing index could have helped a scan-style operation
    --,mir.UserSeeks + mir.UserScans AS [RecIndxReads]
    ,mir.LastUserSeek AS RecIndxLastSeek -- last time a query compiled/executed where SQL Server thought this missing index could help a seek
    ,mir.LastUserScan AS RecIndxLastScan -- last time a query compiled/executed where SQL Server thought this missing index could help a scan
    ,mir.UniqueCompiles -- number of query compilations that contributed to this missing-index recommendation
    ,mir.AvgTotalUserCost
    ,mir.AvgUserImpact
    ,CASE
        WHEN mir.EqualityColumns IS NULL AND mir.InequalityColumns IS NOT NULL THEN 'Inequality-only recommendation - review selectivity carefully'
        WHEN mir.UserSeeks = 0 AND mir.UserScans > 0 THEN 'Scan-only recommendation - review carefully'
        WHEN mir.UserSeeks + mir.UserScans < 10 THEN 'Low read count - review carefully'
        WHEN mir.UniqueCompiles = 1 THEN 'Single compile - review carefully'
        ELSE 'Review candidate'
     END AS ReviewNote
    ,'CREATE NONCLUSTERED INDEX '
        + QUOTENAME(
            LEFT(
                'IX_' + OBJECT_NAME(@TblId, @DBId) + '_'
                + CONVERT(VARCHAR(32), HASHBYTES(
                    'MD5'
                    ,ISNULL(mir.EqualityColumns, '')
                        + ISNULL(mir.InequalityColumns, '')
                        + ISNULL(mir.IncludedColumns, '')
                ), 2)
                ,128
            )
        )
        + ' ON ' + QUOTENAME(DB_NAME(@DBId)) + '.' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(OBJECT_NAME(@TblId, @DBId))
        + ' ('
        + ISNULL(mir.EqualityColumns, '')
        + CASE WHEN mir.EqualityColumns IS NOT NULL AND mir.InequalityColumns IS NOT NULL THEN ', ' ELSE '' END
        + ISNULL(mir.InequalityColumns, '')
        + ')'
        + CASE WHEN mir.IncludedColumns IS NULL THEN ''
            ELSE ' INCLUDE (' + mir.IncludedColumns + ')'
          END
        + ' WITH (ONLINE = ON) ON [PRIMARY];' AS CreateIndexStatement
FROM MissingIndexRanked mir
WHERE mir.ImpactRank <= 500
ORDER BY mir.EstimatedImpact DESC
        ,ISNULL(mir.UserSeeks + mir.UserScans,0) DESC
        ,CreateIndexStatement DESC
OPTION (MAXDOP 2);
/****** POSSIBLE MISSING INDEXES BLOCK END ******/

/****** POSSIBLE LOW-READ / HIGH-WRITE INDEXES BLOCK START ******/
SELECT  'POSSIBLE LOW-READ / HIGH-WRITE INDEXES SINCE LAST RESTART:' AS Info;

SELECT  OBJECT_NAME(i.object_id)                                        AS TblName
       ,i.name                                                          AS IndxName
       ,i.type_desc                                                     AS IndxType
       ,ISNULL(s.user_seeks + s.user_scans + s.user_lookups,0)          AS TotalReads
       ,ISNULL(s.user_updates,0)                                        AS TotalWrites
       ,ISNULL(s.user_updates - (s.user_seeks + s.user_scans + s.user_lookups),0) AS [Difference]
       ,ISNULL(CASE WHEN s.user_updates < 1 THEN 100
					 ELSE 1.00 * (s.user_seeks + s.user_scans + s.user_lookups) / s.user_updates
				END,0)                                                  AS ReadsPerWrite
       ,(SELECT MAX(v.LastRead)
         FROM (
                VALUES (s.last_user_seek),(s.last_user_scan),(s.last_user_lookup)
              ) v(LastRead)
        )                                                               AS LastRead
       ,s.last_user_update                                              AS LastWrite
       ,(
            SELECT  SUM(p.rows)
            FROM    sys.partitions p
            WHERE   p.index_id = i.index_id
            AND     i.object_id = p.object_id
        )                                                               AS [Rows]
       ,CASE WHEN i.is_primary_key = 1
             OR   i.is_unique_constraint = 1 THEN
                 'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(i.object_id)) + '.'
                 + QUOTENAME(OBJECT_NAME(i.object_id)) + ' DROP CONSTRAINT ' + QUOTENAME(i.name)
             ELSE
                 'DROP INDEX IF EXISTS ' + QUOTENAME(i.name) + ' ON ' + QUOTENAME(OBJECT_SCHEMA_NAME(i.object_id)) + '.'
                 + QUOTENAME(OBJECT_NAME(i.object_id))
        END                                                             AS DropStatement
FROM    sys.indexes AS i WITH (NOLOCK)
        LEFT JOIN sys.dm_db_index_usage_stats AS s WITH (NOLOCK)
            ON  s.object_id = i.object_id
            AND i.index_id = s.index_id
			AND OBJECTPROPERTY(s.object_id, 'IsUserTable') = 1
			AND s.database_id = DB_ID()
WHERE   i.object_id = @TblId
AND		i.type_desc = 'NONCLUSTERED'
AND		i.is_primary_key = 0
AND		i.is_unique_constraint = 0
AND 	i.is_unique = 0
AND 	i.is_disabled = 0
AND 	i.is_hypothetical = 0
AND     s.user_updates > (s.user_seeks + s.user_scans + s.user_lookups)
ORDER BY Difference DESC
        ,TotalWrites DESC
        ,TotalReads ASC
OPTION (RECOMPILE, MAXDOP 2);
/****** POSSIBLE LOW-READ / HIGH-WRITE INDEXES BLOCK BLOCK END ******/
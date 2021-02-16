SET NOCOUNT ON;

DECLARE @DBId                INT          = DB_ID()
       ,@SchemaName          sysname
       ,@TblName             sysname      = N'dbo.factloanresponseattribute'
       ,@TblId               INT
       ,@MinFragmentation    REAL         = 5.0 -- Defaulted to 5% as recommended by MS in BOL
       ,@MinPageCount        INT          = 1000 -- Defaulted to 1000 pages as recommended by MS in BOL
       ,@EstimateCompression BIT          = 0 -- Leave off unless specifically looking for compression estimates
       ,@CompressionType     NVARCHAR(60) = N'ROW';

SET @TblId = OBJECT_ID(@TblName);
SET @SchemaName = OBJECT_SCHEMA_NAME(@TblId, @DBId);

/****** INDEX CATALOG BLOCK START ******/
SELECT  'CATALOG:' AS Info;
SELECT  '[' + DB_NAME() + '].[' + @SchemaName + '].[' + OBJECT_NAME(@TblId, @DBId) + ']' AS Object
       ,i.name                                                                           AS [Index]
       ,i.type_desc                                                                      AS [Index Type]
       ,ds.type_desc                                                                     AS [Data Space Type]
       ,ds.name                                                                          AS [Data Space Name]
       ,i.is_primary_key                                                                 AS PK
       ,i.is_unique_constraint                                                           AS AK
       ,i.fill_factor                                                                    AS [Fill Factor]
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
        )                                                                                AS Columns
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
        )                                                                                AS [Included Columns]
       ,ISNULL(s.user_seeks + s.user_scans + s.user_lookups,0)                           AS TotalReads
       ,ISNULL(s.user_updates,0)                                                         AS TotalWrites
FROM    sys.indexes                            i
        INNER JOIN sys.data_spaces             ds
            ON i.data_space_id = ds.data_space_id
        LEFT JOIN sys.dm_db_index_usage_stats AS s
            ON  s.object_id = i.object_id
            AND i.index_id = s.index_id
WHERE   i.object_id = @TblId
AND     i.is_disabled = 0
AND     i.is_hypothetical = 0
ORDER BY i.index_id
		,i.name
OPTION (MAXDOP 2);
/****** INDEX CATALOG BLOCK END ******/

--/****** INDEX SIZE BLOCK START ******/
--DECLARE @tmp_compression TABLE (
--    object_name                                    NVARCHAR(128)
--   ,schema_name                                    NVARCHAR(128)
--   ,index_id                                       INT          PRIMARY KEY CLUSTERED
--   ,partition_number                               INT
--   ,size_with_current_compression_setting          BIGINT
--   ,size_with_requested_compression_setting        BIGINT
--   ,sample_size_with_current_compression_setting   BIGINT
--   ,sample_size_with_requested_compression_setting BIGINT
--);

--IF @EstimateCompression = 1
--    INSERT INTO @tmp_compression (
--        object_name
--		,schema_name
--		,index_id
--		,partition_number
--		,size_with_current_compression_setting
--		,size_with_requested_compression_setting
--		,sample_size_with_current_compression_setting
--		,sample_size_with_requested_compression_setting
--    )
--    EXEC sys.sp_estimate_data_compression_savings
--		@schema_name = @SchemaName
--		,@object_name = @TblName
--		,@index_id = NULL
--		,@partition_number = NULL
--		,@data_compression = @CompressionType;

--SELECT  'SIZE:' AS Info;
--SELECT  '[' + DB_NAME() + '].[' + OBJECT_SCHEMA_NAME(@TblId, @DBId) + '].[' + OBJECT_NAME(@TblId, @DBId) + ']' AS Object
--       ,i.name                                                                                                 AS [Index]
--       ,i.type_desc                                                                                            AS [Index Type]
--	   ,ps.alloc_unit_type_desc                                                                                AS [Allocation Type]
--       ,CONVERT(NUMERIC(9, 2), ps.page_count * 8 * /*convert to MB*/ 0.000976562)                              AS [Index Size (MB)]
--       ,ps.page_count                                                                                          AS Pages
--       ,CONVERT(NUMERIC(5, 2), ps.avg_page_space_used_in_percent)                                              AS [Avg Page Space Used (%)]
--       ,ps.record_count                                                                                        AS Records
--       ,ps.avg_record_size_in_bytes                                                                            AS [Avg Record Size (bytes)]
--       ,ps.compressed_page_count                                                                               AS [Compressed Pages]
--       ,CONVERT(NUMERIC(5, 2), tmp.size_with_requested_compression_setting * /*convert to MB*/ 0.000976562)    AS [Est Compressed Size (MB)]
--       ,'ALTER INDEX [' + i.name + +'] ON ' + '[' + OBJECT_SCHEMA_NAME(@TblId, @DBId) + '].['
--        + OBJECT_NAME(@TblId, @DBId) + ']' + ' REBUILD WITH ( FILLFACTOR = '
--        + CONVERT(   CHAR(3), CASE WHEN i.fill_factor = 0 THEN 100
--                                   ELSE i.fill_factor
--                              END
--                 ) + ', ONLINE=ON, SORT_IN_TEMPDB=ON );' + ' UPDATE STATISTICS [' + OBJECT_SCHEMA_NAME(@TblId, @DBId)
--        + '].[' + OBJECT_NAME(@TblId, @DBId) + '] [' + i.name + +'];'                                          AS [Rebuild Script]
--FROM    sys.dm_db_index_physical_stats(@DBId, @TblId, NULL, NULL, 'SAMPLED') AS ps
--        INNER JOIN sys.indexes                                               i
--            ON  ps.object_id = i.object_id
--            AND ps.index_id = i.index_id
--        LEFT OUTER JOIN @tmp_compression                                     tmp
--            ON i.index_id = tmp.index_id
--WHERE   i.object_id = @TblId
--AND     i.is_disabled = 0
--AND     i.is_hypothetical = 0
--ORDER BY i.index_id
--        ,i.name
--OPTION (MAXDOP 2);
--/****** INDEX SIZE BLOCK END ******/

/****** POSSIBLE MISSING INDEXES BLOCK START ******/
SELECT  'POSSIBLE MISSING (since last restart):' AS Info;
/* ------------------------------------------------------------------
-- Title:	FindMissingIndexes
-- Author:	Brent Ozar
-- Date:	2009-04-01 
-- Modified By: Clayton Kramer <ckramer.kramer @="" gmail.com="">
-- Description: This query returns indexes that SQL Server 2005 
-- (and higher) thinks are missing since the last restart. The 
-- "Impact" column is relative to the time of last restart and how 
-- bad SQL Server needs the index. 10 million+ is high.
-- Changes: Updated to expose full table name. This makes it easier
-- to identify which database needs an index. Modified the 
-- CreateIndexStatement to use the full table path and include the
-- equality/inequality columns for easier identifcation.
------------------------------------------------------------------ */
SELECT  CONVERT(NUMERIC(19, 2), (migs.avg_total_user_cost * migs.avg_user_impact) * (migs.user_seeks + migs.user_scans)) AS Impact
       ,mid.statement                                                                                                    AS [Table]
       ,mid.equality_columns -- table.column = constant_value
       ,mid.inequality_columns -- table.column > constant_value
       ,mid.included_columns
       ,(migs.user_seeks + migs.user_scans)                                                                              AS [Rec Index Reads]
       ,'CREATE NONCLUSTERED INDEX ix_' + o.name COLLATE DATABASE_DEFAULT + '_'
        + REPLACE(
                     REPLACE(
                                REPLACE(ISNULL(mid.equality_columns, '') + ISNULL(mid.inequality_columns, ''), '[', '')
                               ,']', ''
                            ), ', ', '_'
                 ) + ' ON ' + mid.statement + ' ( ' + ISNULL(mid.equality_columns, '')
        + CASE WHEN mid.inequality_columns IS NULL THEN ''
               ELSE CASE WHEN mid.equality_columns IS NULL THEN ''
                         ELSE ','
                    END + mid.inequality_columns
          END + ' ) ' + CASE WHEN mid.included_columns IS NULL THEN ''
                             ELSE 'INCLUDE (' + mid.included_columns + ')'
                        END + ' WITH ( FILLFACTOR = 100 ) ON [PRIMARY]' + ';'                                            AS CreateIndexStatement
FROM    sys.dm_db_missing_index_group_stats        AS migs
        INNER JOIN sys.dm_db_missing_index_groups  AS mig
            ON migs.group_handle = mig.index_group_handle
        INNER JOIN sys.dm_db_missing_index_details AS mid
            ON mig.index_handle = mid.index_handle
        INNER JOIN sys.objects AS o WITH (NOLOCK)
            ON mid.object_id = o.object_id
WHERE   migs.group_handle IN (
            SELECT TOP (500)
					group_handle
            FROM  sys.dm_db_missing_index_group_stats WITH (NOLOCK)
            ORDER BY (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans) DESC
        )
AND     OBJECTPROPERTY(o.object_id, 'isusertable') = 1
AND     o.object_id = @TblId
ORDER BY Impact DESC
        ,CreateIndexStatement DESC
OPTION (MAXDOP 2);
/****** POSSIBLE MISSING INDEXES BLOCK END ******/

/****** POSSIBLE BAD INDEXES BLOCK START ******/
SELECT  'POSSIBLE BAD (since last restart):' AS Info;
SELECT  OBJECT_NAME(i.object_id)                                        AS [Table Name]
       ,i.name                                                          AS [Index Name]
       ,i.type_desc                                                     AS [Index Type]
       ,ISNULL(s.user_seeks + s.user_scans + s.user_lookups,0)          AS [Total Reads]
       ,ISNULL(s.user_updates,0)                                        AS [Total Writes]
       ,ISNULL(s.user_updates - (s.user_seeks + s.user_scans + s.user_lookups),0) AS [Difference]
       ,ISNULL(CASE WHEN s.user_updates < 1 THEN 100
					 ELSE 1.00 * (s.user_seeks + s.user_scans + s.user_lookups) / s.user_updates
				END,0)                                                  AS reads_per_write
       ,(
            SELECT  SUM(p.rows)
            FROM    sys.partitions p
            WHERE   p.index_id = i.index_id
            AND     i.object_id = p.object_id
        )                                                               AS Rows
       ,CASE WHEN i.is_primary_key = 1
             OR   i.is_unique_constraint = 1 THEN
                 'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(i.object_id)) + '.'
                 + QUOTENAME(OBJECT_NAME(i.object_id)) + ' DROP CONSTRAINT ' + QUOTENAME(i.name)
             ELSE
                 'DROP INDEX ' + QUOTENAME(i.name) + ' ON ' + QUOTENAME(OBJECT_SCHEMA_NAME(i.object_id)) + '.'
                 + QUOTENAME(OBJECT_NAME(i.object_id))
        END                                                             AS [Drop Statement]
FROM    sys.indexes AS i WITH (NOLOCK)
        LEFT JOIN sys.dm_db_index_usage_stats AS s WITH (NOLOCK)
            ON  s.object_id = i.object_id
            AND i.index_id = s.index_id
			AND OBJECTPROPERTY(s.object_id, 'IsUserTable') = 1
			AND s.database_id = DB_ID()
WHERE   i.index_id > 1
AND     i.object_id = @TblId
AND     s.user_updates > (s.user_seeks + s.user_scans + s.user_lookups)
ORDER BY Difference DESC
        ,[Total Writes] DESC
        ,[Total Reads] ASC
OPTION (RECOMPILE, MAXDOP 2);
/****** POSSIBLE BAD INDEXES BLOCK END ******/
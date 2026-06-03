/*
Identify missing-index candidates from SQL Server missing-index DMVs for the current database.
*/

SET NOCOUNT ON;

DECLARE @DBId        INT     = DB_ID()
        ,@SchemaName SYSNAME = NULL
        ,@TblName    SYSNAME = NULL
        ,@TblId      INT
        ,@TopN       INT     = 500;

IF @TblName IS NOT NULL
BEGIN
    SET @TblId = OBJECT_ID(
                    CASE 
                        WHEN @SchemaName IS NULL THEN QUOTENAME(@TblName)
                        ELSE QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TblName)
                    END
                );
END;

WITH MissingIndexBase AS (
    SELECT  mid.index_handle
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
        JOIN sys.dm_db_missing_index_groups mig
            ON migs.group_handle = mig.index_group_handle
        JOIN sys.dm_db_missing_index_details mid
            ON mig.index_handle = mid.index_handle
    WHERE mid.database_id = @DBId
),
MissingIndexRanked AS (
    SELECT  mib.*
            ,ROW_NUMBER() OVER (
                ORDER BY mib.EstimatedImpact DESC
                        ,mib.UserSeeks + mib.UserScans DESC
                        ,mib.LastUserSeek DESC
            ) AS ImpactRank
    FROM MissingIndexBase mib
)
SELECT  mir.EstimatedImpact
        ,mir.ImpactRank
        ,SCHEMA_NAME(o.schema_id) AS SchemaName
        ,o.name AS TblName
        ,mir.FullObjectName AS DMVObjectName
        ,mir.EqualityColumns
        ,mir.InequalityColumns
        ,mir.IncludedColumns
        ,mir.UserSeeks
        ,mir.UserScans
        ,mir.UserSeeks + mir.UserScans AS RecIndexReads
        ,mir.LastUserSeek
        ,mir.LastUserScan
        ,mir.UniqueCompiles
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
                    'IX_' + o.name + '_' 
                    + CONVERT(VARCHAR(32), HASHBYTES(
                        'MD5',
                        ISNULL(mir.EqualityColumns, '') 
                        + ISNULL(mir.InequalityColumns, '') 
                        + ISNULL(mir.IncludedColumns, '')
                    ), 2),
                    128
                )
            )
            + ' ON ' + QUOTENAME(DB_NAME(@DBId)) + '.' + QUOTENAME(SCHEMA_NAME(o.schema_id)) + '.' + QUOTENAME(o.name)
            + ' ('
            + ISNULL(mir.EqualityColumns, '')
            + CASE 
                WHEN mir.EqualityColumns IS NOT NULL AND mir.InequalityColumns IS NOT NULL THEN ', '
                ELSE ''
              END
            + ISNULL(mir.InequalityColumns, '')
            + ')'
            + CASE 
                WHEN mir.IncludedColumns IS NULL THEN ''
                ELSE ' INCLUDE (' + mir.IncludedColumns + ')'
              END
            + ';' AS CreateIndexStatement
FROM MissingIndexRanked mir
    JOIN sys.objects o
        ON mir.object_id = o.object_id
WHERE o.type = 'U'
  AND o.is_ms_shipped = 0
  AND mir.ImpactRank <= @TopN
  AND (@SchemaName IS NULL OR SCHEMA_NAME(o.schema_id) = @SchemaName)
  AND (@TblName IS NULL OR o.object_id = @TblId)
ORDER BY schemaname, tblname, mir.EstimatedImpact DESC
        ,RecIndexReads DESC
        ,CreateIndexStatement DESC
OPTION (MAXDOP 2);
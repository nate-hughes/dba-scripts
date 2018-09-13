USE [?];
GO

CREATE TABLE #PlanCacheIndexes (
    StatementText VARCHAR(4000)
   ,DatabaseName  VARCHAR(128)
   ,SchemaName    VARCHAR(128)
   ,TableName     VARCHAR(128)
   ,IndexName     VARCHAR(128)
   ,Indextype     VARCHAR(128)
   ,QueryPlan     XML
   ,UseCounts     BIGINT
);

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @TableName AS NVARCHAR(128) = 'TableName';

-- Make sure the name passed is appropriately quoted
IF (LEFT(@TableName, 1) <> '[' AND  RIGHT(@TableName, 1) <> ']')
    SET @TableName = QUOTENAME(@TableName);
-- Handle the case where the left or right was quoted manually but not the opposite side
IF LEFT(@TableName, 1) <> '['
    SET @TableName = '[' + @TableName;
IF RIGHT(@TableName, 1) <> ']'
    SET @TableName = @TableName + ']';

-- Collect parallel plan information
-- Dig into the plan cache and find all plans using Indexes
WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
INSERT INTO #PlanCacheIndexes (
    StatementText
    ,DatabaseName
    ,SchemaName
    ,TableName
    ,IndexName
    ,Indextype
    ,QueryPlan
    ,UseCounts
)
SELECT  stmt.value('(@StatementText)[1]', 'varchar(max)') AS SQL_Text
       ,obj.value('(@Database)[1]', 'varchar(128)')       AS DatabaseName
       ,obj.value('(@Schema)[1]', 'varchar(128)')         AS SchemaName
       ,obj.value('(@Table)[1]', 'varchar(128)')          AS TableName
       ,obj.value('(@Index)[1]', 'varchar(128)')          AS IndexName
       ,obj.value('(@IndexKind)[1]', 'varchar(128)')      AS IndexKind
       ,qp.query_plan
       ,cp.usecounts
FROM    sys.dm_exec_cached_plans                           AS cp
        CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
        CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS batch(stmt)
        CROSS APPLY stmt.nodes('.//IndexScan/Object[@Table=sql:variable("@TableName")]') AS TableName(obj)
OPTION (MAXDOP 1, RECOMPILE);
GO

DECLARE @TableName AS NVARCHAR(128) = 'TableName';

-- Return plan information
SELECT  'Plan Cache Indexes'                          AS ResultType
       ,REPLACE(REPLACE(IndexName, '[', ''), ']', '') AS IndexName
       ,Indextype
       ,COUNT(IndexName)                              AS IndexUsageInstances
       ,SUM(UseCounts)                                AS TimesIndexUsed
FROM   #PlanCacheIndexes
GROUP BY IndexName
        ,Indextype
ORDER BY SUM(UseCounts) DESC;


-- Return Index usage stats for indexes that are not used in the plan cache
WITH IndexesUsed AS (
    SELECT  DISTINCT
            REPLACE(REPLACE(IndexName, '[', ''), ']', '') AS IndexName
    FROM    #PlanCacheIndexes
)
SELECT  'Index Usage Not In Plan Cache'                    AS ResultType
       ,I.name                                             AS IndexName
       ,IUS.user_seeks + IUS.user_scans + IUS.user_lookups AS UserReads
       ,IUS.user_updates
FROM    sys.dm_db_index_usage_stats IUS
        INNER JOIN sys.indexes      I
            ON  IUS.object_id = I.object_id
            AND I.index_id = IUS.index_id
        LEFT OUTER JOIN IndexesUsed IU
            ON I.name = IU.IndexName
WHERE   i.object_id = OBJECT_ID(@TableName)
AND		IU.IndexName IS NULL;


-- find out that last time the index stats where reset
-- How old are the index usage stats?
WITH IndexesUsed AS (
    SELECT  DISTINCT
            REPLACE(REPLACE(IndexName, '[', ''), ']', '') AS IndexName
    FROM    #PlanCacheIndexes
)
SELECT  'Index Stats Age'                                              AS ResultType
       ,I.name                                                         AS IndexName
       ,CASE WHEN IU.IndexName IS NOT NULL THEN 'Y'
             ELSE ''
        END                                                            AS Cached
       ,DATEDIFF(HOUR, STATS_DATE(I.object_id, I.index_id), GETDATE()) AS StatsAge_HRs
FROM    sys.indexes                 I
        LEFT OUTER JOIN IndexesUsed IU
            ON I.name = IU.IndexName
WHERE   I.object_id = OBJECT_ID(@TableName);
GO

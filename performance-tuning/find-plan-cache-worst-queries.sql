--******************
-- (C) 2013, Brent Ozar Unlimited. 
-- See http://BrentOzar.com/go/eula for the End User Licensing Agreement.

--This script suitable only for test purposes.
--Scripts may contain treacherous commands that are bad for production servers!
--******************


--Let's look at the top ranking queries in the plan cache
--We're looking by CPU
--This query works with only 2008 and higher
DECLARE @DBID SMALLINT = DB_ID('rp_prod');

;WITH top_queries_by_hash AS (
    SELECT  TOP (25)
            qs.query_hash
           ,COUNT(DISTINCT qs.plan_handle)     AS number_of_plans
           ,COUNT(DISTINCT qs.query_plan_hash) AS distinct_plans
           ,MAX(qs.plan_handle)                AS max_plan_handle
           ,MAX(qs.plan_generation_num)        AS max_plan_generation_number
           ,MIN(qs.creation_time)              AS min_creation_time
           ,MAX(qs.last_execution_time)        AS max_last_execution_time
           ,SUM(qs.execution_count)            AS execution_count
           ,SUM(qs.total_worker_time)          AS total_worker_time
           ,SUM(qs.total_physical_reads)       AS total_physical_reads
           ,SUM(qs.total_logical_writes)       AS total_logical_writes
           ,SUM(qs.total_logical_reads)        AS total_logical_reads
           ,SUM(qs.total_clr_time)             AS total_clr_time
           ,SUM(qs.total_elapsed_time)         AS total_elapsed_time
    FROM    sys.dm_exec_query_stats                         qs
            CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
    WHERE   st.dbid = @DBID
    GROUP BY qs.query_hash
    ORDER BY total_worker_time DESC
)
SELECT  tq.number_of_plans                                                                                                         AS [# Plans]
       ,tq.distinct_plans                                                                                                          AS [Distinct Plans]
       ,tq.total_worker_time / tq.execution_count                                                                                  AS [Avg CPU]
       ,tq.total_worker_time                                                                                                       AS [Total CPU]
       ,CAST(ROUND(100.00 * tq.total_worker_time / (SELECT  SUM(total_worker_time) FROM sys.dm_exec_query_stats), 2) AS MONEY)     AS [% CPU]
       ,CAST(tq.total_elapsed_time / tq.execution_count / 1000. AS BIGINT)                                                         AS [Avg Duration ms]
       ,CAST(ROUND(tq.total_elapsed_time / 1000., 2) AS BIGINT)                                                                    AS [Total Duration ms]
       ,CAST(ROUND(100.00 * tq.total_elapsed_time / (SELECT SUM(total_elapsed_time) FROM    sys.dm_exec_query_stats), 2) AS MONEY)    AS [% Duration]
       ,tq.total_logical_reads / tq.execution_count                                                                                AS [Avg Reads]
       ,tq.total_logical_reads                                                                                                     AS [Total Reads]
       ,CAST(ROUND(100.00 * tq.total_logical_reads / (SELECT    SUM(total_logical_reads) FROM   sys.dm_exec_query_stats), 2) AS MONEY) AS [% Reads]
       ,tq.execution_count                                                                                                         AS [Execution Count]
       ,CAST(ROUND(100.00 * tq.execution_count / (SELECT    SUM(execution_count) FROM   sys.dm_exec_query_stats), 2) AS MONEY)         AS [% Executions]
       ,CASE DATEDIFF(mi, tq.min_creation_time, tq.max_last_execution_time)
             WHEN 0 THEN 0
             ELSE
                 CAST((1.00 * tq.execution_count / DATEDIFF(mi, tq.min_creation_time, tq.max_last_execution_time)) AS MONEY)
        END                                                                                                                        AS [Executions/Min]
       ,tq.min_creation_time                                                                                                       AS [Earliest Plan Created]
       ,tq.max_last_execution_time                                                                                                 AS [Last Execution Time]
       ,tq.query_hash                                                                                                              AS [Query Hash]
       ,OBJECT_NAME(st.objectid)                                                                                                   AS [SP Name]
       ,SUBSTRING(   st.text, (qs.statement_start_offset / 2) + 1, ((CASE qs.statement_end_offset
                                                                          WHEN -1 THEN DATALENGTH(st.text)
                                                                          ELSE qs.statement_end_offset
                                                                     END - qs.statement_start_offset
                                                                    ) / 2
                                                                   ) + 1
                 )                                                                                                                 AS query_text
       ,qp.query_plan
FROM    top_queries_by_hash                             tq
        JOIN sys.dm_exec_query_stats                    qs
            ON  tq.query_hash = qs.query_hash
            AND tq.max_plan_handle = qs.plan_handle
        CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
        CROSS APPLY sys.dm_exec_query_plan(tq.max_plan_handle) AS qp
--ORDER BY [Total CPU] DESC
ORDER BY [Avg Duration ms] DESC
OPTION (RECOMPILE);
--To order by [Total Reads], change it in the top CTE as well as here
GO



--Query #1
--Action plan: Indexing on Production.Transation history
--Research the ant-pattern in the where clause











--Query #2
--Action plan: Easy first step-- indexes on Person.Address











--Query #3
--Action plan: Test parameterization








--Query #4
--Action Plan: Identify how to cache







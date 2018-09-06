USE rp_prod;
GO

DECLARE @l_SPName sysname;
--SET @l_SPName = 'GetLoansForDeal'

-- Get Top 100 executed SP's ordered by execution count
SELECT  TOP (100)
        qt.text                                                            AS [SP Name]
       ,qs.execution_count                                                 AS [Execution Count]
       ,qs.execution_count / DATEDIFF(SECOND, qs.creation_time, GETDATE()) AS [Calls/Second]
       ,qs.total_worker_time / qs.execution_count                          AS AvgWorkerTime
       ,qs.total_worker_time                                               AS TotalWorkerTime
       ,qs.total_elapsed_time / qs.execution_count                         AS AvgElapsedTime
       ,qs.max_logical_reads
       ,qs.max_logical_writes
       ,qs.total_physical_reads
       ,DATEDIFF(MINUTE, qs.creation_time, GETDATE())                      AS [Age in Cache]
FROM    sys.dm_exec_query_stats                         AS qs
        CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE   qt.dbid = DB_ID() -- Filter by current database
ORDER BY qs.execution_count DESC;

-- Get Top 20 executed SP's ordered by total worker time (CPU pressure)
SELECT  TOP (20)
        qt.text                                                                       AS [SP Name]
       ,qs.total_worker_time                                                          AS TotalWorkerTime
       ,qs.total_worker_time / qs.execution_count                                     AS AvgWorkerTime
       ,qs.execution_count                                                            AS [Execution Count]
       ,ISNULL(qs.execution_count / DATEDIFF(SECOND, qs.creation_time, GETDATE()), 0) AS [Calls/Second]
       ,ISNULL(qs.total_elapsed_time / qs.execution_count, 0)                         AS AvgElapsedTime
       ,qs.max_logical_reads
       ,qs.max_logical_writes
       ,DATEDIFF(MINUTE, qs.creation_time, GETDATE())                                 AS [Age in Cache]
FROM    sys.dm_exec_query_stats                         AS qs
        CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE   qt.dbid = DB_ID() -- Filter by current database
ORDER BY qs.total_worker_time DESC;

-- Get Top 20 executed SP's ordered by logical reads (memory pressure)
SELECT  TOP (20)
        qt.text                                                            AS [SP Name]
       ,qs.total_logical_reads
       ,qs.execution_count                                                 AS [Execution Count]
       ,qs.total_logical_reads / qs.execution_count                        AS AvgLogicalReads
       ,qs.execution_count / DATEDIFF(SECOND, qs.creation_time, GETDATE()) AS [Calls/Second]
       ,qs.total_worker_time / qs.execution_count                          AS AvgWorkerTime
       ,qs.total_worker_time                                               AS TotalWorkerTime
       ,qs.total_elapsed_time / qs.execution_count                         AS AvgElapsedTime
       ,qs.total_logical_writes
       ,qs.max_logical_reads
       ,qs.max_logical_writes
       ,qs.total_physical_reads
       ,DATEDIFF(MINUTE, qs.creation_time, GETDATE())                      AS [Age in Cache]
       ,qt.dbid
FROM    sys.dm_exec_query_stats                         AS qs
        CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE   qt.dbid = DB_ID() -- Filter by current database
ORDER BY qs.total_logical_reads DESC;

-- Get Top 20 executed SP's ordered by physical reads (read I/O pressure)
SELECT  TOP (20)
        qt.text                                                            AS [SP Name]
       ,qs.total_physical_reads
       ,qs.total_physical_reads / qs.execution_count                       AS [Avg Physical Reads]
       ,qs.execution_count                                                 AS [Execution Count]
       ,qs.execution_count / DATEDIFF(SECOND, qs.creation_time, GETDATE()) AS [Calls/Second]
       ,qs.total_worker_time / qs.execution_count                          AS AvgWorkerTime
       ,qs.total_worker_time                                               AS TotalWorkerTime
       ,qs.total_elapsed_time / qs.execution_count                         AS AvgElapsedTime
       ,qs.max_logical_reads
       ,qs.max_logical_writes
       ,DATEDIFF(MINUTE, qs.creation_time, GETDATE())                      AS [Age in Cache]
       ,qt.dbid
FROM    sys.dm_exec_query_stats                         AS qs
        CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE   qt.dbid = DB_ID() -- Filter by current database
ORDER BY qs.total_physical_reads DESC;

-- Get Top 20 executed SP's ordered by logical writes/minute
SELECT  TOP (20)
        qt.text                                                                 AS [SP Name]
       ,qs.total_logical_writes
       ,qs.total_logical_writes / NULLIF(qs.execution_count, 0)                 AS AvgLogicalWrites
       ,qs.total_logical_writes / DATEDIFF(MINUTE, qs.creation_time, GETDATE()) AS [Logical Writes/Min]
       ,qs.execution_count                                                      AS [Execution Count]
       ,qs.execution_count / DATEDIFF(SECOND, qs.creation_time, GETDATE())      AS [Calls/Second]
       ,qs.total_worker_time / NULLIF(qs.execution_count, 0)                    AS AvgWorkerTime
       ,qs.total_worker_time                                                    AS TotalWorkerTime
       ,qs.total_elapsed_time / NULLIF(qs.execution_count, 0)                   AS AvgElapsedTime
       ,qs.max_logical_reads
       ,qs.max_logical_writes
       ,qs.total_physical_reads
       ,DATEDIFF(MINUTE, qs.creation_time, GETDATE())                           AS [Age in Cache]
       ,qs.total_physical_reads / NULLIF(qs.execution_count, 0)                 AS [Avg Physical Reads]
       ,qt.dbid
FROM    sys.dm_exec_query_stats                         AS qs
        CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE   qt.dbid = DB_ID() -- Filter by current database
ORDER BY qs.total_logical_writes DESC;

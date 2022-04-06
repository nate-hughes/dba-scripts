/*
Does My SQL Server Need More Memory?
https://www.erikdarlingdata.com/sql-server/does-my-sql-server-need-more-memory/
*/

WITH 
    unused AS
(
    SELECT TOP (100)
        oldest_plan = 
            MIN(deqs.creation_time) OVER(),
        newest_plan = 
            MAX(deqs.creation_time) OVER(),
        deqs.statement_start_offset,
        deqs.statement_end_offset,
        deqs.plan_handle,
        deqs.execution_count,
        deqs.max_grant_kb / 1024 as max_grant_mb,
        deqs.max_used_grant_kb / 1024 as max_used_grant_mb,
        unused_grant = 
            (deqs.max_grant_kb - deqs.max_used_grant_kb) / 1024,
        (deqs.min_spills * 8) / 1024 as min_spills_mb,
        (deqs.max_spills * 8) / 1024 as max_spills_mb
    FROM sys.dm_exec_query_stats AS deqs
    WHERE (deqs.max_grant_kb - deqs.max_used_grant_kb) > 1024.
    AND   deqs.max_grant_kb > 5120.
    ORDER BY unused_grant DESC
)
SELECT      
    plan_cache_age_hours = 
        DATEDIFF
        (
            HOUR,
            u.oldest_plan,
            u.newest_plan
        ),
    query_text = 
        (
            SELECT [processing-instruction(query)] =
                SUBSTRING
                (
                    dest.text, 
                    ( u.statement_start_offset / 2 ) + 1,
                    (
                        ( 
                            CASE u.statement_end_offset 
                                 WHEN -1 
                                 THEN DATALENGTH(dest.text) 
                                 ELSE u.statement_end_offset 
                            END - u.statement_start_offset 
                        ) / 2 
                    ) + 1
                )
                FOR XML PATH(''), 
                    TYPE
        ),
    deqp.query_plan,
    u.execution_count,
    u.max_grant_mb,
    u.max_used_grant_mb,
    u.min_spills_mb,
    u.max_spills_mb,
    u.unused_grant as unused_grant_mb
FROM unused AS u
OUTER APPLY sys.dm_exec_sql_text(u.plan_handle) AS dest
OUTER APPLY sys.dm_exec_query_plan(u.plan_handle) AS deqp
ORDER BY u.unused_grant DESC
OPTION (RECOMPILE, MAXDOP 1);
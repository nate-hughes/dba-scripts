/*
Measure the Effect of “Cost Threshold for Parallelism”
https://michaeljswart.com/2022/01/measure-the-effect-of-cost-threshold-for-parallelism/?utm_source=pocket_mylist
*/

WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT 
        sql_text.[text] AS sqltext,
        qp.query_plan,
        xml_values.subtree_cost AS estimated_query_cost_in_query_bucks,
        qs.last_dop,
        CAST( qs.total_worker_time / (qs.execution_count + 0.0) AS money ) AS average_query_cpu_in_microseconds,
        qs.total_worker_time,
        qs.execution_count,
        qs.query_hash,
        qs.query_plan_hash,
        qs.plan_handle,
        qs.sql_handle      
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
CROSS APPLY sys.dm_exec_query_plan (qs.plan_handle) qp
CROSS APPLY 
        (
                SELECT SUBSTRING(st.[text],(qs.statement_start_offset + 2) / 2,
                (CASE 
                        WHEN qs.statement_end_offset = -1  THEN LEN(CONVERT(NVARCHAR(MAX),st.[text])) * 2
                        ELSE qs.statement_end_offset + 2
                        END - qs.statement_start_offset) / 2)
        ) AS sql_text([text])
OUTER APPLY 
        ( 
                SELECT 
                        n.c.value('@QueryHash', 'NVARCHAR(30)')  AS query_hash,
                        n.c.value('@StatementSubTreeCost', 'FLOAT')  AS subtree_cost
                FROM qp.query_plan.nodes('//StmtSimple') AS n(c)
        ) xml_values
WHERE qs.last_dop > 1
AND sys.fn_varbintohexstr(qs.query_hash) = xml_values.query_hash
AND execution_count > 10
ORDER BY xml_values.subtree_cost
OPTION (RECOMPILE);
SELECT  SUBSTRING(   ST.text, (QS.statement_start_offset / 2) + 1, ((CASE QS.statement_end_offset
                                                                          WHEN -1 THEN DATALENGTH(ST.text)
                                                                          ELSE QS.statement_end_offset
                                                                     END - QS.statement_start_offset
                                                                    ) / 2
                                                                   ) + 1
                 )                                        AS "Statement Text"
       ,QS.total_worker_time / QS.execution_count / 1000  AS "Average Worker Time (ms)"
       ,QS.execution_count                                AS "Execution Count"
       ,QS.total_worker_time / 1000                       AS "Total Worker Time (ms)"
       ,QS.total_logical_reads                            AS "Total Logical Reads"
       ,QS.total_logical_reads / QS.execution_count       AS "Average Logical Reads"
       ,QS.total_elapsed_time / 1000                      AS "Total Elapsed Time (ms)"
       ,QS.total_elapsed_time / QS.execution_count / 1000 AS "Average Elapsed Time (ms)"
       ,QP.query_plan                                     AS "Query Plan (double click to open)"
FROM    sys.dm_exec_query_stats                         QS
        CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) ST
        CROSS APPLY sys.dm_exec_query_plan(QS.plan_handle) QP
ORDER BY QS.total_elapsed_time / QS.execution_count DESC;
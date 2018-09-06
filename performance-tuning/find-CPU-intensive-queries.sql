DECLARE @l_RowCount INT;

SET @l_RowCount = 100;

SELECT  TOP (@l_RowCount)
        RANK() OVER (ORDER BY deqs.total_worker_time DESC)                                              AS Rank
       ,CONVERT(DECIMAL(38, 2), CONVERT(FLOAT, deqs.total_worker_time) / 1000)                          AS [Total CPU Time (ms)]
       ,deqs.execution_count                                                                            AS [Execution Count]
       ,CONVERT(DECIMAL(38, 2), (CONVERT(FLOAT, deqs.total_worker_time) / deqs.execution_count) / 1000) AS [Average CPU Time (ms)]
       ,SUBSTRING(   execText.text -- starting value for substring 
                    ,CASE WHEN deqs.statement_start_offset = 0
                          OR   deqs.statement_start_offset IS NULL THEN 1
                          ELSE deqs.statement_start_offset / 2 + 1
                     END -- ending value for substring
                    ,CASE WHEN deqs.statement_end_offset = 0
                          OR   deqs.statement_end_offset = -1
                          OR   deqs.statement_end_offset IS NULL THEN LEN(execText.text)
                          ELSE deqs.statement_end_offset / 2
                     END - CASE WHEN deqs.statement_start_offset = 0
                                OR   deqs.statement_start_offset IS NULL THEN 1
                                ELSE deqs.statement_start_offset / 2
                           END + 1
                 )                                                                                      AS [Query Text]
       ,execText.text                                                                                   AS [Object Text]
FROM    sys.dm_exec_query_stats                            deqs
        CROSS APPLY sys.dm_exec_sql_text(deqs.plan_handle) AS execText
ORDER BY deqs.total_worker_time DESC;

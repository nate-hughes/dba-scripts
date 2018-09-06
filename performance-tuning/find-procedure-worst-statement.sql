DECLARE @sql_handle VARBINARY(64);

SELECT  @sql_handle = sql_handle
FROM    sys.dm_exec_procedure_stats
WHERE   object_id = OBJECT_ID('dbo.p_dv_get_raked_tranche_nonsense');

SELECT  CAST(qp.query_plan AS XML) AS XML_Plan
       ,SUBSTRING(
                     st.text, qs.statement_start_offset / 2 + 1
                    ,((CASE WHEN qs.statement_end_offset = -1 THEN DATALENGTH(st.text)
                            ELSE qs.statement_end_offset
                       END
                      ) - qs.statement_start_offset
                     ) / 2 + 1
                 )                 AS SqlText
       ,qs.*
FROM    sys.dm_exec_query_stats                         qs
        CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
        CROSS APPLY sys.dm_exec_text_query_plan(qs.plan_handle, qs.statement_start_offset, qs.statement_end_offset) qp
WHERE   qs.sql_handle = @sql_handle;

/***** SCRIPT NEEDS EITHER @proc OR @sql_text TO WORK *****/
DECLARE @proc VARCHAR(200) = 'Salesforce_Reporting_January2018'
		,@sql_text VARCHAR(MAX) = NULL--''
;

SELECT  q.query_id,
        q.query_hash,
        q.initial_compile_start_time,
        q.last_compile_start_time,
        q.last_execution_time,
		OBJECT_NAME(q.object_id) AS sproc,
        qt.query_sql_text
		,SUM(rs.count_executions) AS count_executions
		,TRY_CONVERT(BIGINT,MIN(rs.min_duration) * 0.001 * 0.001) AS min_duration_s
		,TRY_CONVERT(BIGINT,MAX(rs.max_duration) * 0.001 * 0.001) AS max_duration_s
		,MIN(rs.min_logical_io_reads) * 8 / 1024 AS min_logical_io_reads_mb
		,MAX(rs.max_logical_io_reads) * 8 / 1024 AS max_logical_io_reads_mb
		,MIN(rs.min_logical_io_writes) * 8 / 1024 AS min_logical_io_writes_mb
		,MAX(rs.max_logical_io_writes) * 8 / 1024 AS max_logical_io_writes_mb
		,MIN(rs.min_physical_io_reads) * 8 / 1024 AS min_physical_io_reads_mb
		,MAX(rs.max_physical_io_reads) * 8 / 1024 AS max_physical_io_reads_mb
		,MIN(rs.min_query_max_used_memory) * 8 / 1024 AS min_query_max_used_memory_mb
		,MAX(rs.max_query_max_used_memory) * 8 / 1024 AS max_query_max_used_memory_mb
		,MIN(rs.min_tempdb_space_used) * 8 / 1024 AS min_tempdb_space_used_mb
		,MAX(rs.max_tempdb_space_used) * 8 / 1024 AS max_tempdb_space_used_mb
		,MIN(rs.min_rowcount) AS min_rowcount
		,MAX(rs.max_rowcount) AS max_rowcount
FROM    sys.query_store_query q
        INNER JOIN sys.query_store_query_text qt ON qt.query_text_id = q.query_text_id
		INNER JOIN sys.query_store_plan p ON q.query_id = p.query_id
		INNER JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
WHERE (@proc IS NULL OR q.object_id = OBJECT_ID(@proc))
AND	(@sql_text IS NULL OR qt.query_sql_text LIKE '%' + @sql_text + '%')
AND rs.execution_type = 0 -- Regular execution (successfully finished)
GROUP BY q.query_id,
        q.query_hash,
        q.initial_compile_start_time,
        q.last_compile_start_time,
        q.last_execution_time,
		q.object_id,
		qt.query_sql_text
ORDER BY q.last_execution_time ASC;


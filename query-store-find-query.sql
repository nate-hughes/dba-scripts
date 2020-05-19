/***** SCRIPT NEEDS EITHER @proc OR @sql_text TO WORK *****/
DECLARE @proc VARCHAR(200) = 'SprocName'
		,@sql_text VARCHAR(MAX) = NULL--'';

SELECT  q.query_id,
        q.query_hash,
        q.initial_compile_start_time,
        q.last_compile_start_time,
        q.last_execution_time,
		OBJECT_NAME(q.object_id) AS sproc,
        qt.query_sql_text		
FROM    sys.query_store_query q
        INNER JOIN sys.query_store_query_text qt ON qt.query_text_id = q.query_text_id
WHERE (@proc IS NULL OR q.object_id = OBJECT_ID(@proc))
AND	(@sql_text IS NULL OR qt.query_sql_text LIKE '%' + @sql_text + '%')
ORDER BY q.last_execution_time DESC;

--MarketDataServer.SecurityMaster_SyncSecurityIDs
--366609

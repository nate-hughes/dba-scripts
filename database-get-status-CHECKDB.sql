DECLARE @session_id INT;

SELECT  @session_id = session_id
FROM    sys.dm_exec_requests
WHERE   command LIKE '%DBCC%';

SELECT  session_id
       ,start_time
       ,command
       ,percent_complete
       ,total_elapsed_time
       ,estimated_completion_time
       ,database_id
       ,user_id
       ,last_wait_type
FROM    sys.dm_exec_requests
WHERE   session_id = @session_id;

-- NOTE: for Enterprise Edition, CHECKDB respects the MAXDOP setting configured for the instance
-- https://www.sqlskills.com/blogs/erin/dbcc-checkdb-parallel-checks-and-sql-server-edition/
SELECT  o.name
       ,o.schema_id
       ,o.type_desc
FROM    sys.dm_tran_locks      l
        INNER JOIN sys.objects o
            ON l.resource_associated_entity_id = o.object_id
WHERE   l.request_session_id = @session_id
AND     l.resource_type = 'OBJECT'
AND     l.resource_associated_entity_id > 50;

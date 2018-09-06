-- Note: querying sys.dm_os_buffer_descriptors
-- requires the VIEW_SERVER_STATE permission.

DECLARE @total_buffer INT;

SELECT  @total_buffer = cntr_value
FROM    sys.dm_os_performance_counters
WHERE   RTRIM(object_name) LIKE '%Buffer Manager'
AND     counter_name = 'Total Pages';

;WITH src AS (
    SELECT  database_id
           ,COUNT_BIG(*) AS db_buffer_pages
    FROM    sys.dm_os_buffer_descriptors
    --WHERE database_id BETWEEN 5 AND 32766
    GROUP BY database_id
)
SELECT  CASE src.database_id
             WHEN 32767 THEN 'Resource DB'
             ELSE DB_NAME(src.database_id)
        END                                                                 AS db_name
       ,src.db_buffer_pages
       ,src.db_buffer_pages / 128                                           AS db_buffer_MB
       ,CONVERT(DECIMAL(6, 3), src.db_buffer_pages * 100.0 / @total_buffer) AS db_buffer_percent
FROM    src
ORDER BY db_buffer_MB DESC;


USE rp_prod;
GO

;WITH src AS (
     SELECT o.name               AS Object
           ,o.type_desc          AS Type
           ,COALESCE(i.name, '') AS [Index]
           ,i.type_desc          AS Index_Type
           ,p.object_id
           ,p.index_id
           ,au.allocation_unit_id
     FROM   sys.partitions                  AS p
            INNER JOIN sys.allocation_units AS au
                ON p.hobt_id = au.container_id
            INNER JOIN sys.objects          AS o
                ON p.object_id = o.object_id
            INNER JOIN sys.indexes          AS i
                ON  o.object_id = i.object_id
                AND p.index_id = i.index_id
     WHERE  au.type IN (1, 2, 3)
     AND    o.is_ms_shipped = 0
 )
SELECT  src.Object
       ,src.Type
       ,src.[Index]
       ,src.Index_Type
       ,COUNT_BIG(b.page_id)       AS buffer_pages
       ,COUNT_BIG(b.page_id) / 128 AS buffer_mb
FROM    src
        INNER JOIN sys.dm_os_buffer_descriptors AS b
            ON src.allocation_unit_id = b.allocation_unit_id
WHERE   b.database_id = DB_ID()
GROUP BY src.Object
        ,src.Type
        ,src.[Index]
        ,src.Index_Type
ORDER BY buffer_pages DESC;
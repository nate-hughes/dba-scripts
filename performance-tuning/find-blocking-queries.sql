-- https://blog.sqlauthority.com/2010/10/06/sql-server-quickest-way-to-identify-blocking-query-and-resolution-dirty-solution/

SELECT  db.name                  AS DBName
       ,tl.request_session_id
       ,wt.blocking_session_id
       ,OBJECT_NAME(p.object_id) AS BlockedObjectName
       ,tl.resource_type
       ,h1.text                  AS RequestingText
       ,h2.text                  AS BlockingTest
       ,tl.request_mode
FROM    sys.dm_tran_locks                                            AS tl
        INNER JOIN sys.databases                                     db
            ON db.database_id = tl.resource_database_id
        INNER JOIN sys.dm_os_waiting_tasks                           AS wt
            ON tl.lock_owner_address = wt.resource_address
        INNER JOIN sys.partitions                                    AS p
            ON p.hobt_id = tl.resource_associated_entity_id
        INNER JOIN sys.dm_exec_connections                           ec1
            ON ec1.session_id = tl.request_session_id
        INNER JOIN sys.dm_exec_connections                           ec2
            ON ec2.session_id = wt.blocking_session_id
        CROSS APPLY sys.dm_exec_sql_text(ec1.most_recent_sql_handle) AS h1
        CROSS APPLY sys.dm_exec_sql_text(ec2.most_recent_sql_handle) AS h2;
GO
USE ApplicationProcessor;
GO

SELECT Cast(tl.[request_session_id] AS BIGINT) AS [session_id]
       ,s.HOST_NAME
       ,s.[program_name]
       ,s.[login_name]
       ,Db_name(tl.[resource_database_id]) AS [database_name]
       ,Cast(tl.[resource_associated_entity_id] AS BIGINT) AS OBJECT_ID
       ,Object_name(tl.[resource_associated_entity_id], tl.[resource_database_id]) AS OBJECT_NAME
       ,tl.[request_mode] AS lock_mode
       ,tl.[request_status] AS lock_status
       ,tl.[request_owner_type] AS lock_owner_type
       ,Cast(tl.[request_lifetime] AS BIGINT) AS lock_lifetime_seconds
       ,blocking_session.[session_id] AS [blocking_session_id]
FROM   [sys].[dm_tran_locks] AS tl
       JOIN [sys].[dm_exec_sessions] AS s ON tl.[request_session_id] = s.[session_id]
       LEFT JOIN [sys].[dm_exec_requests] AS blocking_request ON tl.[request_session_id] = blocking_request.[session_id]
       LEFT JOIN [sys].[dm_exec_sessions] AS blocking_session ON blocking_request.[blocking_session_id] = blocking_session.[session_id]
WHERE  tl.[resource_database_id] = Db_id()
       AND tl.[resource_type] = 'OBJECT'
       AND tl.[request_session_id] NOT IN (
			SELECT [session_id]
			FROM   [sys].[dm_exec_requests]
			WHERE  [command] = 'DB STARTUP'
			AND [database_id] = Db_id()
		)
ORDER BY lock_lifetime_seconds desc
		,tl.[request_session_id]; 
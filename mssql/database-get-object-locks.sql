
DECLARE	@find_replication_blocker BIT = 1
		,@database_name SYSNAME = DB_NAME()
		,@session_id INT;

IF @find_replication_blocker = 1
	SELECT	@session_id = session_id
	FROM	sys.dm_exec_requests
	WHERE	command = 'DB STARTUP'
	AND		db_name(database_id) = @database_name;
ELSE
	SET @session_id = @@SPID;

 -- List all Locks of the Current Database 
SELECT TL.resource_type AS ResType 
      ,TL.resource_description AS ResDescr 
      ,TL.request_mode AS ReqMode 
      ,TL.request_type AS ReqType 
      ,TL.request_status AS ReqStatus 
      ,TL.request_owner_type AS ReqOwnerType 
      ,TAT.[name] AS TransName 
      ,TAT.transaction_begin_time AS TransBegin 
      ,DATEDIFF(ss, TAT.transaction_begin_time, GETDATE()) AS TransDura 
      ,ES.session_id AS S_Id 
      ,ES.login_name AS LoginName 
      ,COALESCE(OBJ.name, PAROBJ.name) AS ObjectName 
      ,PARIDX.name AS IndexName 
      ,ES.host_name AS HostName 
      ,ES.program_name AS ProgramName 
FROM sys.dm_tran_locks AS TL 
     INNER JOIN sys.dm_exec_sessions AS ES 
         ON TL.request_session_id = ES.session_id 
     LEFT JOIN sys.dm_tran_active_transactions AS TAT 
         ON TL.request_owner_id = TAT.transaction_id 
            AND TL.request_owner_type = 'TRANSACTION' 
     LEFT JOIN sys.objects AS OBJ 
         ON TL.resource_associated_entity_id = OBJ.object_id 
            AND TL.resource_type = 'OBJECT' 
     LEFT JOIN sys.partitions AS PAR 
         ON TL.resource_associated_entity_id = PAR.hobt_id 
            AND TL.resource_type IN ('PAGE', 'KEY', 'RID', 'HOBT') 
     LEFT JOIN sys.objects AS PAROBJ 
         ON PAR.object_id = PAROBJ.object_id 
     LEFT JOIN sys.indexes AS PARIDX 
         ON PAR.object_id = PARIDX.object_id 
            AND PAR.index_id = PARIDX.index_id 
WHERE TL.resource_database_id  = DB_ID() 
AND	ES.session_id <> @session_id -- Exclude "my" OR AlwaysOn replication session 
-- optional filter  
--AND TL.request_mode <> 'S' -- Exclude simple shared locks 
--AND TL.resource_associated_entity_id = OBJECT_ID(N'schema.table')
ORDER BY S_Id
		,TL.resource_type 
        ,TL.request_mode 
        ,TL.request_type 
        ,TL.request_status 
        ,ObjectName 
        ,ES.login_name;

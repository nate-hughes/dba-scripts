DECLARE @tracefile VARCHAR(500);

-- Get path of default trace file
SELECT  @tracefile = CAST(value AS VARCHAR(500))
FROM::fn_trace_getinfo(DEFAULT)
WHERE   traceid = 1
AND     property = 2;

-- Get security changes from the default trace
SELECT  trcdata.EventClass AS EventId
       ,cat.name           AS EventCategory
       ,evt.name           AS EventName
       ,trcdata.*
FROM::fn_trace_gettable(@tracefile, DEFAULT) trcdata -- DEFAULT means all trace files will be read
    INNER JOIN sys.trace_events              evt
        ON trcdata.EventClass = evt.trace_event_id
    INNER JOIN sys.trace_categories          cat
        ON evt.category_id = cat.category_id
WHERE   trcdata.EventClass IN (
			102  -- Audit Database Scope GDR: GRANT, DENY, REVOKE issued for a statement
			,103 -- Audit Object GDR Event: GRANT, DENY, REVOKE issued for an object
			,104 -- Audit AddLogin Event: SQL Server login is added or removed
			,105 -- Audit Login GDR Event: Windows login is added or removed
			,106 -- Audit Login Change Property Event: property of a login, except passwords, is modified
			,107 -- Audit Login Change Password Event: SQL Server login password is changed
			,108 -- Audit Add Login to Server Role Event: login is added or removed from a fixed server role
			,109 -- Audit Add DB User Event: login is added or removed as a database user (Windows or SQL Server) to a database
			,110 -- Audit Add Member to DB Role Event: login is added or removed as a database user (fixed or user-defined) to a database
			,111 -- Audit Add Role Event: login is added or removed as a database user to a database
			,112 -- Audit App Role Change Password Event: password of an application role is changed
		)
ORDER BY trcdata.StartTime;

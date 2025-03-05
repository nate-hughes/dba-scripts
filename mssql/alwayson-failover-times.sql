-- Script to determine failover times in Availability Group 

;WITH cte_HADR AS (SELECT object_name, CONVERT(XML, event_data) AS data
FROM sys.fn_xe_file_target_read_file('AlwaysOn*.xel', null, null, null)
WHERE object_name = 'error_reported'
)

SELECT data.value('(/event/@timestamp)[1]','datetime') AS [timestamp],
       data.value('(/event/data[@name=''error_number''])[1]','int') AS [error_number],
       data.value('(/event/data[@name=''message''])[1]','varchar(max)') AS [message]
FROM cte_HADR
WHERE data.value('(/event/data[@name=''error_number''])[1]','int') = 1480

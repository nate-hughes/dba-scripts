
SELECT @@SERVERNAME AS servername 
	,name 
	,message_id 
	,severity 
	,enabled 
	,delay_between_responses 
	,include_event_description 
	,has_notification
FROM msdb.dbo.sysalerts;

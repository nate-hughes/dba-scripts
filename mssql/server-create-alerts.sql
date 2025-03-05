USE [msdb];
GO

/********** START AG ALERTS **********/
-- 1480 - AG Role Change (failover)
EXEC sp_delete_alert @name= N'AG Role Change';
GO
EXEC msdb.dbo.sp_add_alert
    @name = N'AG Role Change'
   ,@message_id = 1480
   ,@severity = 0
   ,@enabled = 0
   ,@delay_between_responses = 0
   ,@include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'AG Role Change', @operator_name=N'DBAs', @notification_method = 1;
GO
-- 35264 - AG Data Movement - Resumed
EXEC sp_delete_alert @name= N'AG Data Movement - Suspended';
GO
EXEC msdb.dbo.sp_add_alert
    @name = N'AG Data Movement - Suspended'
   ,@message_id = 35264
   ,@severity = 0
   ,@enabled = 0
   ,@delay_between_responses = 0
   ,@include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'AG Data Movement - Suspended', @operator_name=N'DBAs', @notification_method = 1;
GO
-- 35265 - AG Data Movement - Resumed
EXEC sp_delete_alert @name= N'AG Data Movement - Resumed';
GO
EXEC msdb.dbo.sp_add_alert
    @name = N'AG Data Movement - Resumed'
   ,@message_id = 35265
   ,@severity = 0
   ,@enabled = 0
   ,@delay_between_responses = 0
   ,@include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'AG Data Movement - Resumed', @operator_name=N'DBAs', @notification_method = 1;
GO
/********** END AG ALERTS **********/

EXEC sp_delete_alert @name=N'Error Msg Severity 17';
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Msg Severity 17', 
		@message_id=0, 
		@severity=17, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Msg Severity 17', @operator_name=N'DBAs', @notification_method = 1;
GO
EXEC sp_delete_alert @name=N'Error Msg Severity 18';
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Msg Severity 18', 
		@message_id=0, 
		@severity=18, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Msg Severity 18', @operator_name=N'DBAs', @notification_method = 1;
GO
EXEC sp_delete_alert @name=N'Error Msg Severity 19';
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Msg Severity 19', 
		@message_id=0, 
		@severity=19, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Msg Severity 19', @operator_name=N'DBAs', @notification_method = 1;
GO
EXEC sp_delete_alert @name=N'Error Msg Severity 20';
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Msg Severity 20', 
		@message_id=0, 
		@severity=20, 
		@enabled=0, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Msg Severity 20', @operator_name=N'DBAs', @notification_method = 1;
GO
EXEC sp_delete_alert @name=N'Error Msg Severity 21';
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Msg Severity 21', 
		@message_id=0, 
		@severity=21, 
		@enabled=0, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Msg Severity 21', @operator_name=N'DBAs', @notification_method = 1;
GO
EXEC sp_delete_alert @name=N'Error Msg Severity 22';
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Msg Severity 22', 
		@message_id=0, 
		@severity=22, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Msg Severity 22', @operator_name=N'DBAs', @notification_method = 1;
GO
EXEC sp_delete_alert @name=N'Error Msg Severity 23';
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Msg Severity 23', 
		@message_id=0, 
		@severity=23, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Msg Severity 23', @operator_name=N'DBAs', @notification_method = 1;
GO
EXEC sp_delete_alert @name=N'Error Msg Severity 24';
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Msg Severity 24', 
		@message_id=0, 
		@severity=24, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Msg Severity 24', @operator_name=N'DBAs', @notification_method = 1;
GO
EXEC sp_delete_alert @name=N'Error Msg Severity 25';
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Msg Severity 25', 
		@message_id=0, 
		@severity=25, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Msg Severity 25', @operator_name=N'DBAs', @notification_method = 1;
GO

EXEC sp_delete_alert @name=N'Error Msg Severity 823';
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Msg Severity 823', 
		@message_id=823, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Msg Severity 823', @operator_name=N'DBAs', @notification_method = 1;
GO
EXEC sp_delete_alert @name=N'Error Msg Severity 824';
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Msg Severity 824', 
		@message_id=824, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Msg Severity 824', @operator_name=N'DBAs', @notification_method = 1;
GO
EXEC sp_delete_alert @name=N'Error Msg Severity 825';
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Msg Severity 825', 
		@message_id=825, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Msg Severity 825', @operator_name=N'DBAs', @notification_method = 1;
GO

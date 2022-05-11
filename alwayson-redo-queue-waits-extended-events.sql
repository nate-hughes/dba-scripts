/*
Troubleshooting REDO queue build-up (data latency issues) on AlwaysOn Readable Secondary Replicas using the WAIT_INFO Extended Event
https://techcommunity.microsoft.com/t5/sql-server-support-blog/troubleshooting-redo-queue-build-up-data-latency-issues-on/ba-p/318488
*/

-- find all the sessions involved in parallel recovery on the secondary
SELECT	db_name(database_id) as DBName
		,session_id
FROM	sys.dm_exec_requests
WHERE	command = 'DB STARTUP';

-- plug in session id
CREATE EVENT SESSION [redo_wait_info] ON SERVER
ADD EVENT sqlos.wait_info(
ACTION(package0.event_sequence,
sqlos.scheduler_id,
sqlserver.database_id,
sqlserver.session_id)
WHERE (
	[opcode]=(1)
    AND sqlserver.session_id = (43)
))
ADD TARGET package0.event_file(
SET filename=N'x:\audit\redo_wait_info')
WITH (MAX_MEMORY=4096 KB,
EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
MAX_DISPATCH_LATENCY=30 SECONDS,
MAX_EVENT_SIZE=0 KB,
MEMORY_PARTITION_MODE=NONE,
TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

-- collect waits
ALTER EVENT SESSION [redo_wait_info] ON SERVER STATE=START
WAITFOR DELAY '00:00:30'
ALTER EVENT SESSION [redo_wait_info] ON SERVER STATE=STOP

/*
Troubleshooting REDO queue build-up (data latency issues) on AlwaysOn Readable Secondary Replicas using the WAIT_INFO Extended Event
https://techcommunity.microsoft.com/t5/sql-server-support-blog/troubleshooting-redo-queue-build-up-data-latency-issues-on/ba-p/318488
*/

-- find all the sessions involved in parallel recovery on the secondary
SELECT	DB_NAME(database_id) AS DBName
		,session_id
FROM	sys.dm_exec_requests
WHERE	command = 'DB STARTUP';


-- plug in session id and create EE session
IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = 'redo_wait_info')
    DROP EVENT SESSION [redo_wait_info] ON SERVER;
GO
CREATE EVENT SESSION [redo_wait_info] ON SERVER
ADD EVENT sqlos.wait_info(
ACTION(package0.event_sequence,
sqlos.scheduler_id,
sqlserver.database_id,
sqlserver.session_id)
WHERE (
	[opcode]=(1)
    AND sqlserver.session_id = (60)
))
ADD TARGET package0.event_file(
SET filename=N'x:\audit\redo_wait_info')
WITH (MAX_MEMORY=4096 KB,
EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
MAX_DISPATCH_LATENCY=30 SECONDS,
MAX_EVENT_SIZE=0 KB,
MEMORY_PARTITION_MODE=NONE,
TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF);
GO


-- start EE session
ALTER EVENT SESSION [redo_wait_info] ON SERVER STATE=START;
-- get session file name needed for decipher step below
SELECT	s.name AS session_name,
		t.target_name,
		CAST(t.target_data AS XML).value('(EventFileTarget/File/@name)[1]', 'nvarchar(max)') AS FILE_NAME
FROM sys.dm_xe_sessions AS s
	JOIN sys.dm_xe_session_targets  AS t ON s.address = t.event_session_address
WHERE s.name = 'redo_wait_info';
-- collect waits
WAITFOR DELAY '00:00:30';
-- stop EE session
ALTER EVENT SESSION [redo_wait_info] ON SERVER STATE=STOP;
GO


-- decipher waits
DECLARE @FileName VARCHAR(MAX) = 'x:\audit\redo_wait_info_0_133637249863850000.xel';

--shred wait_info Xevents
DROP TABLE IF EXISTS #WaitInfo;
WITH EventData_CTE (OBJECT_NAME, EventData)
AS (
	SELECT OBJECT_NAME, CAST(event_data AS XML) EventData
	FROM sys.fn_xe_file_target_read_file(@FileName, NULL, NULL, NULL)
)
SELECT OBJECT_NAME, EventData.value('(event/@timestamp)[1]', 'datetime2') AS TIMESTAMP,
    EventData.value('(event/data[@name="wait_type"]/text)[1]', 'varchar(max)') AS WaitType,
    EventData.value('(event/data[@name="duration"]/value)[1]', 'bigint') AS Duration,
    EventData.value('(event/data[@name="signal_duration"]/value)[1]', 'bigint') AS Signal_Duration,
    EventData.value('(event/action[@name="session_id"]/value)[1]', 'int') AS Session_ID,
    EventData.value('(event/action[@name="scheduler_id"]/value)[1]', 'int') AS Scheduler_ID,
    EventData.value('(event/action[@name="event_sequence"]/value)[1]', 'int') AS EventSequenceNum,
    EventData
INTO #WaitInfo
FROM EventData_CTE;

SELECT Session_ID
	,WaitType
	,COUNT(WaitType) AS Counts
    ,SUM(Duration) AS Sum_Duration
    ,SUM(Signal_Duration) AS Sum_SignalDuration
FROM #WaitInfo
GROUP BY Session_ID, WaitType
ORDER BY Session_ID, SUM(Duration) DESC;

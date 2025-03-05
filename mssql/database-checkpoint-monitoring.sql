/*
"0 to 60" : Switching to indirect checkpoints
https://sqlperformance.com/2020/05/system-configuration/0-to-60-switching-to-indirect-checkpoints

SQL Server Checkpoint Monitoring with Extended Events
https://www.mssqltips.com/sqlservertip/6319/sql-server-checkpoint-monitoring-with-extended-events
*/

-- START: CREATE EE SESSION TO TRACK CHECKPOINT DURATIONS --
CREATE EVENT SESSION CheckpointTracking ON SERVER 
ADD EVENT sqlserver.checkpoint_begin (
  WHERE   (
       sqlserver.database_id = 19 -- db4
    OR sqlserver.database_id = 78 -- db2
  )
)
, ADD EVENT sqlserver.checkpoint_end (
  WHERE   (
       sqlserver.database_id = 19 -- db4
    OR sqlserver.database_id = 78 -- db2
  )
)
ADD TARGET package0.event_file (
  SET filename = N'X:\Audit\CheckPointTracking.xel',
      max_file_size = 50, -- MB
      max_rollover_files = 50
)
WITH (
  MAX_MEMORY = 4096 KB,
  MAX_DISPATCH_LATENCY = 30 SECONDS, 
  TRACK_CAUSALITY = ON,
  STARTUP_STATE = ON
);
GO
 
ALTER EVENT SESSION CheckpointTracking ON SERVER 
  STATE = START;
GO
-- END: CREATE EE SESSION TO TRACK CHECKPOINT DURATIONS --


-- START: REVIEW EE SESSION DATA --
DROP TABLE IF EXISTS #xml;
GO
SELECT ev = SUBSTRING([object_name],12,5), ed = CONVERT(xml, event_data)
 INTO #xml
 FROM sys.fn_xe_file_target_read_file('L:\XE_Out\CheckPoint*.xel', NULL, NULL, NULL);
;WITH Events(ev,ts,db,id) AS
(
  SELECT ev,
    ed.value(N'(event/@timestamp)[1]', N'datetime'),
    ed.value(N'(event/data[@name="database_id"]/value)[1]', N'int'),
    ed.value(N'(event/action[@name="attach_activity_id"]/value)[1]', N'uniqueidentifier')
  FROM #xml
), 
EventPairs AS
(
  SELECT db, ev, 
    checkpoint_ended = ts, 
    checkpoint_began = LAG(ts, 1) OVER (PARTITION BY id, db ORDER BY ts)
  FROM Events
),
Timings AS
(
  SELECT 
    dbname = DB_NAME(db), 
    checkpoint_began, 
    checkpoint_ended,
    duration_milliseconds = DATEDIFF(MILLISECOND, checkpoint_began, checkpoint_ended) 
  FROM EventPairs WHERE ev = 'end' AND checkpoint_began IS NOT NULL
)
SELECT 
  dbname,
  checkpoint_count    = COUNT(*),
  avg_seconds         = CONVERT(decimal(18,2),AVG(1.0*duration_milliseconds)/1000),
  max_seconds         = CONVERT(decimal(18,2),MAX(1.0*duration_milliseconds)/1000),
  total_seconds_spent = CONVERT(decimal(18,2),SUM(1.0*duration_milliseconds)/1000)
FROM Timings
GROUP BY dbname
ORDER BY total_seconds_spent DESC;
-- END: REVIEW EE SESSION DATA --


-- START: SWITCH TO INDIRECT CHECKPOINTS --
ALTER DATABASE dbA SET TARGET_RECOVERY_TIME = 60 SECONDS;
SELECT db = DB_ID(N'dbA'), ts = sysutcdatetime() INTO #db;
-- END: SWITCH TO INDIRECT CHECKPOINTS --


-- START: REVIEW AFTER EE SESSION DATA --
drop table if exists #db;
create table #db (db int, ts datetime2);
insert #db values (19,'2022-03-24 13:14:44.0892394'), (78, '2022-03-24 17:00:58.7504078');

DROP TABLE IF EXISTS #xml;
GO
SELECT ev = SUBSTRING([object_name],12,5), ed = CONVERT(xml, event_data)
 INTO #xml
 FROM sys.fn_xe_file_target_read_file('X:\Audit\CheckPoint*.xel', NULL, NULL, NULL);
;WITH Events(ev,ts,db,id) AS
(
  SELECT ev,
    ed.value(N'(event/@timestamp)[1]', N'datetime'),
    ed.value(N'(event/data[@name="database_id"]/value)[1]', N'int'),
    ed.value(N'(event/action[@name="attach_activity_id"]/value)[1]', N'uniqueidentifier')
  FROM #xml
), 
EventPairs AS
(
  SELECT db, ev, 
    checkpoint_ended = ts, 
    checkpoint_began = LAG(ts, 1) OVER (PARTITION BY id, db ORDER BY ts)
  FROM Events
),
Timings AS
(
  SELECT 
    dbname = DB_NAME(ep.db)
           + CASE WHEN ep.checkpoint_began < db.ts THEN ' (before)' ELSE ' (after)' END, 
    ep.checkpoint_began, 
    ep.checkpoint_ended,
    duration_milliseconds = DATEDIFF(MILLISECOND, ep.checkpoint_began, ep.checkpoint_ended) 
  FROM EventPairs AS ep
	INNER JOIN #db AS db ON db.db = ep.db
  WHERE ep.ev = 'end' AND ep.checkpoint_began IS NOT NULL
)
SELECT 
  dbname,
  checkpoint_count    = COUNT(*),
  avg_seconds         = CONVERT(decimal(18,2),AVG(1.0*duration_milliseconds)/1000),
  max_seconds         = CONVERT(decimal(18,2),MAX(1.0*duration_milliseconds)/1000),
  total_seconds_spent = CONVERT(decimal(18,2),SUM(1.0*duration_milliseconds)/1000)
FROM Timings
GROUP BY dbname
ORDER BY dbname,total_seconds_spent DESC;
-- END: REVIEW AFTER EE SESSION DATA --
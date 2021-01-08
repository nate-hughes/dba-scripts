DECLARE @path VARCHAR(500)
		,@tracefilename VARCHAR(500)
		,@indx INT;

SELECT	@path = path
FROM	sys.traces
WHERE	is_default = 1;

SET @path = REVERSE(@path);
SET @indx = PATINDEX('%\%', @path);
SET @path = REVERSE(@path);
SET @tracefilename = LEFT(@path, LEN(@path) - @indx) + '\log.trc';

SELECT	DatabaseName, 
		te.name, 
		Filename, 
		CONVERT(DECIMAL(10, 3), Duration / 1000000e0) AS TimeTakenSeconds, 
		StartTime, 
		EndTime, 
		(IntegerData * 8.0 / 1024) AS 'ChangeInSize MB', 
		ApplicationName, 
		HostName, 
		LoginName
FROM	sys.fn_trace_gettable(@tracefilename, DEFAULT) t
		JOIN sys.trace_events te ON t.EventClass = te.trace_event_id
WHERE	(te.trace_event_id >= 92 AND te.trace_event_id <= 95)
OR		(te.trace_event_id = 116 AND t.TextData like 'DBCC%SHRINK%')
ORDER BY t.StartTime;




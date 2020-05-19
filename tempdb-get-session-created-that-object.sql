-- https://dba.stackexchange.com/questions/61703/find-which-session-is-holding-which-temporary-table

DECLARE @FileName VARCHAR(MAX);

SELECT  @FileName = SUBSTRING(path, 0, LEN(path) - CHARINDEX('\', REVERSE(path)) + 1) + '\Log.trc'
FROM    sys.traces
WHERE   is_default = 1;

SELECT  o.name
       ,o.object_id
       ,o.create_date
       ,gt.NTUserName
       ,gt.HostName
       ,gt.SPID
       ,gt.DatabaseName
       ,gt.TextData
FROM    sys.fn_trace_gettable(@FileName, DEFAULT) AS gt
        JOIN tempdb.sys.objects                   AS o
            ON gt.ObjectID = o.object_id
WHERE   gt.DatabaseID = 2
AND     gt.EventClass = 46 -- (Object:Created Event from sys.trace_events)  
AND     o.create_date >= DATEADD(ms, -100, gt.StartTime)
AND     o.create_date <= DATEADD(ms, 100, gt.StartTime);
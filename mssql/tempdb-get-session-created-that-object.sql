-- https://dba.stackexchange.com/questions/61703/find-which-session-is-holding-which-temporary-table
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO

DECLARE @FileName VARCHAR(MAX);

SELECT  @FileName = SUBSTRING(path, 0, LEN(path) - CHARINDEX('\', REVERSE(path)) + 1) + '\Log.trc'
FROM    sys.traces
WHERE   is_default = 1;

SELECT  o.name
       ,o.object_id
       ,o.create_date
       ,gt.SPID
       ,gt.DatabaseName
       ,gt.TextData
	   ,ts.StatRowCount
	   ,ts.RevervedSizeKB
		,S.login_name
		,S.host_name
		,S.program_name
		,S.status
FROM    sys.fn_trace_gettable(@FileName, DEFAULT) AS gt
        JOIN tempdb.sys.objects                   AS o
            ON gt.ObjectID = o.object_id
		JOIN (
			SELECT STAT.object_id
				,TBL.name AS ObjName 
				,STAT.row_count AS StatRowCount 
				,STAT.used_page_count * 8 AS UsedSizeKB 
				,STAT.reserved_page_count * 8 AS RevervedSizeKB 
			FROM tempdb.sys.partitions AS PART 
				INNER JOIN tempdb.sys.dm_db_partition_stats AS STAT 
					ON PART.partition_id = STAT.partition_id 
					AND PART.partition_number = STAT.partition_number 
				INNER JOIN tempdb.sys.tables AS TBL 
					ON STAT.object_id = TBL.object_id 
		 ) ts ON o.object_id = ts.object_id
		JOIN sys.dm_exec_sessions s ON s.session_id = gt.SPID
WHERE   gt.DatabaseID = 2
AND     gt.EventClass = 46 -- (Object:Created Event from sys.trace_events)  
AND     o.create_date >= DATEADD(ms, -100, gt.StartTime)
AND     o.create_date <= DATEADD(ms, 100, gt.StartTime)
--AND		gt.SPID = 419
ORDER BY RevervedSizeKB DESC

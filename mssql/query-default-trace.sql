/*
http://jasonbrimhall.info/2018/12/28/sql-servers-black-box-recorder-def-trace/
*/

-- generic
DECLARE	@path NVARCHAR(260);

SELECT	@path=path
FROM	sys.traces
WHERE	is_default = 1;

SELECT	DISTINCT
		TE.name AS EventName, DT.DatabaseName, DT.ApplicationName, DT.ObjectName, DT.LoginName, DT.StartTime
FROM	fn_trace_gettable (@path,  DEFAULT) DT
		INNER JOIN sys.trace_events AS TE
			ON DT.EventClass = te.trace_event_id;

-- events and categories that are configured for capture in the default trace
SELECT te.name AS EventName
		,tca.name AS CategoryName
		, CASE tca.type WHEN '0' THEN 'Normal'
				WHEN '1' THEN 'Connection'
				WHEN '2' THEN 'ERROR' END AS CategoryType
		, t.path AS TracePath
		, oa.logical_operator,oa.comparison_operator, oa.value AS FilteredValue
	FROM sys.traces t
		CROSS APPLY (SELECT DISTINCT gei.eventid FROM sys.fn_trace_geteventinfo(t.id) gei) ca
		INNER JOIN sys.trace_events te
			ON te.trace_event_id = ca.eventid
		INNER JOIN sys.trace_categories tca
			ON te.category_id = tca.category_id
		OUTER APPLY (SELECT gfi.columnid,gfi.logical_operator,gfi.comparison_operator,gfi.value FROM sys.fn_trace_getfilterinfo(t.id) gfi) oa
	WHERE t.is_default = 1


-- server configs Audited via Def Trace
SELECT 	T.StartTime
		, T.SPID
		, T.LoginName
		, T.HostName
		, T.ApplicationName
		, T.DatabaseName
		--, ObjectName,sv.number AS ObjTypeVal, sv.name [ObjectType]
		--, T.TextData
		, ConfigOption = SUBSTRING(T.TextData,CHARINDEX('''',T.TextData)+1,CHARINDEX(' changed from ',T.TextData)-CHARINDEX('''',T.TextData)-2)
		, PrevValue = SUBSTRING(T.TextData,CHARINDEX('from ',T.TextData)+5,CHARINDEX('to ',T.TextData)-CHARINDEX('from ',T.TextData)-5)
		, NewValue = SUBSTRING(T.TextData,CHARINDEX('to ',T.TextData)+3,CHARINDEX('. Run',T.TextData)-CHARINDEX('to ',T.TextData)-3)
		, EventName = te.name
		, T.EventClass
	FROM sys.fn_trace_gettable(CONVERT(VARCHAR(150), 
			( SELECT REVERSE(SUBSTRING(REVERSE(path),
					CHARINDEX('\',REVERSE(path)),256)) + 'log.trc'
				FROM    sys.traces
				WHERE   is_default = 1)), DEFAULT) AS T  
		INNER JOIN sys.trace_events AS te
			ON T.EventClass = te.trace_event_id
	WHERE T.EventClass = 22
		AND T.TextData LIKE '%config%'
	ORDER BY T.StartTime DESC;
DECLARE @default_trace_path VARCHAR(500)
        ,@tracefilename VARCHAR(500)
        ,@indx INT;

SET @default_trace_path = (SELECT path FROM sys.traces WHERE is_default = 1);
SET @default_trace_path = REVERSE(@default_trace_path);
SELECT @indx  = PATINDEX('%\%', @default_trace_path);
SET @default_trace_path = REVERSE(@default_trace_path);
SET @tracefilename = LEFT( @default_trace_path,LEN(@default_trace_path) - @indx) + '\log.trc';

SELECT	SUBSTRING(CONVERT(NVARCHAR(MAX),TEXTData),36, PATINDEX('%executed%',TEXTData)-36) [Command]
		,LoginName
		,StartTime
		,CONVERT(INT,SUBSTRING(CONVERT(NVARCHAR(MAX),TEXTData),PATINDEX('%found%',TEXTData)+6,PATINDEX('%errors %',TEXTData)-PATINDEX('%found%',TEXTData)-6)) [Errors], CONVERT(INT,SUBSTRING(CONVERT(NVARCHAR(MAX),TEXTData),PATINDEX('%repaired%',TEXTData)+9,PATINDEX('%errors.%',TEXTData)-PATINDEX('%repaired%',TEXTData)-9)) [Repaired]
		,SUBSTRING(CONVERT(NVARCHAR(MAX),TEXTData),PATINDEX('%time:%',TEXTData)+6,PATINDEX('%hours%',TEXTData)-PATINDEX('%time:%',TEXTData)-6)+':'+SUBSTRING(CONVERT (NVARCHAR(MAX),TEXTData),PATINDEX('%hours%',TEXTData)+6,PATINDEX('%minutes%',TEXTData)-PATINDEX('%hours%',TEXTData)-6)+':'+SUBSTRING(CONVERT(NVARCHAR (MAX),TEXTData),PATINDEX('%minutes%',TEXTData)+8,PATINDEX('%seconds.%',TEXTData)-PATINDEX('%minutes%',TEXTData)-8) [Duration]
FROM	::fn_trace_gettable( @tracefilename, DEFAULT) 
WHERE	EventClass = 22 
AND		SUBSTRING(TEXTData,36,12) = 'DBCC CHECKDB'
ORDER BY StartTime DESC;

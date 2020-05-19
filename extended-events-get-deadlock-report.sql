--Extracting Deadlock information using SYSTEM_HEALTH Extended Events
--https://www.sqlservercentral.com/blogs/extracting-deadlock-information-using-system_health-extended-events
CREATE TABLE #errorlog (
	LogDate DATETIME 
	, ProcessInfo VARCHAR(100)
	, [Text] VARCHAR(MAX)
);

DECLARE	@tag VARCHAR (MAX)
		,@path VARCHAR(MAX)
		,@DateTimeOffset INT = DATEDIFF(HOUR,GETUTCDATE(),GETDATE());

INSERT INTO #errorlog EXEC sp_readerrorlog;

SELECT	@tag = [Text]
FROM	#errorlog 
WHERE	[Text] LIKE 'Logging%MSSQL\Log%';

DROP TABLE IF EXISTS #errorlog;

SET @path = SUBSTRING(@tag, 38, CHARINDEX('MSSQL\Log', @tag) - 29);

SELECT	CONVERT(xml, event_data).query('/event/data/value/child::*') AS DeadlockReport
		,DATEADD(HOUR,@DateTimeOffset,CONVERT(xml, event_data).value('(event[@name="xml_deadlock_report"]/@timestamp)[1]', 'datetime')) AS Execution_Time
FROM	sys.fn_xe_file_target_read_file (@path + '\system_health*.xel', NULL, NULL, NULL)
WHERE	OBJECT_NAME like 'xml_deadlock_report'
ORDER BY Execution_Time DESC;

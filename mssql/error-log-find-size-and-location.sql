DECLARE @logfiles TABLE (
	[FileArchive] TINYINT,
	[Date] DATETIME,
	[LogFileSizeB] BIGINT
);

INSERT @logfiles
EXEC xp_enumerrorlogs;

SELECT	[FileArchive]
		,[Date]
		,CONVERT(VARCHAR(50),CAST(SUM(CAST([LogFileSizeB] AS FLOAT)) / 1024 / 1024 AS DECIMAL(10,4))) + ' MB' SizeMB
FROM	@logfiles
GROUP BY [FileArchive]
		,[Date]
		,[LogFileSizeB];

-- to identify error log file location
SELECT SERVERPROPERTY('ErrorLogFileName') [Error_Log_Location];

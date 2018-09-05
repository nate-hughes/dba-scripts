USE rp_util;
GO

-- START: DDL --
IF OBJECT_ID('T_UTIL_CheckDbLog', 'U') IS NULL
    CREATE TABLE dbo.T_UTIL_CheckDbLog (
        CheckDbLogId INT           IDENTITY(1, 1) NOT NULL
       ,LogDate      DATETIME      NOT NULL
       ,LogText      NVARCHAR(MAX) NOT NULL
       ,AlertSent    BIT           NOT NULL CONSTRAINT df_T_UTIL_CheckDbLog_AlertSent DEFAULT 0
       ,Mitigated    BIT           NOT NULL CONSTRAINT df_T_UTIL_CheckDbLog_Mitigated DEFAULT 0
       ,MitigatedBy  NVARCHAR(128) NULL
       ,Mitigation   NVARCHAR(MAX) NULL
       ,CONSTRAINT PK_T_UTIL_CheckDbLog PRIMARY KEY CLUSTERED (CheckDbLogId) WITH FILLFACTOR = 100 ON [PRIMARY]
                                                              );
GO

IF OBJECT_ID('upd_T_UTIL_CheckDbLog', 'TR') IS NOT NULL
    DROP TRIGGER dbo.upd_T_UTIL_CheckDbLog;
GO

CREATE TRIGGER dbo.upd_T_UTIL_CheckDbLog
ON dbo.T_UTIL_CheckDbLog
INSTEAD OF UPDATE
AS
BEGIN
    UPDATE  l
    SET l.Mitigated = ins.Mitigated
       ,l.MitigatedBy = COALESCE(ins.MitigatedBy, SYSTEM_USER)
       ,l.Mitigation = ins.Mitigation
    FROM    dbo.T_UTIL_CheckDbLog l
            INNER JOIN INSERTED   ins
                ON l.CheckDbLogId = ins.CheckDbLogId;
END;
GO
-- END: DDL --

-- START: ALERT --
USE msdb;
GO

SET NOCOUNT ON;

CREATE TABLE #CHECKDBLog (LogDate DATETIME, ProcessInfo NVARCHAR(128), Text NVARCHAR(MAX));


DECLARE @recipients NVARCHAR(100)
       ,@query      NVARCHAR(MAX);

-- read last 6 log files (catchall in case server has been restarted)
INSERT INTO #CHECKDBLog (LogDate, ProcessInfo, Text)
EXEC sys.xp_readerrorlog 0, 1, 'DBCC CHECKDB';
INSERT INTO #CHECKDBLog (LogDate, ProcessInfo, Text)
EXEC sys.xp_readerrorlog 1, 1, 'DBCC CHECKDB';
INSERT INTO #CHECKDBLog (LogDate, ProcessInfo, Text)
EXEC sys.xp_readerrorlog 2, 1, 'DBCC CHECKDB';
INSERT INTO #CHECKDBLog (LogDate, ProcessInfo, Text)
EXEC sys.xp_readerrorlog 3, 1, 'DBCC CHECKDB';
INSERT INTO #CHECKDBLog (LogDate, ProcessInfo, Text)
EXEC sys.xp_readerrorlog 4, 1, 'DBCC CHECKDB';
INSERT INTO #CHECKDBLog (LogDate, ProcessInfo, Text)
EXEC sys.xp_readerrorlog 5, 1, 'DBCC CHECKDB';

INSERT INTO rp_util.dbo.T_UTIL_CheckDbLog (LogDate, LogText)
SELECT  LogDate
       ,Text
FROM    #CHECKDBLog
WHERE   DATEDIFF(HOUR, LogDate, GETDATE()) <= 24
AND     Text NOT LIKE '%found 0 errors and repaired 0 errors%';

IF EXISTS (SELECT   1 FROM  rp_util.dbo.T_UTIL_CheckDbLog WHERE AlertSent = 0)
BEGIN
    SELECT  @recipients = email_address
    FROM    msdb.dbo.sysoperators
    WHERE   name = 'DBAs';

    SET @query = N'SELECT [Text] FROM rp_util.dbo.T_UTIL_CheckDbLog WHERE AlertSent = 0';

    EXEC msdb.dbo.sp_send_dbmail @recipients = @recipients
                                ,@subject = 'DBCC CHECKDB found errors'
                                ,@query = @query
                                ,@attach_query_result_as_file = 0
                                ,@query_result_no_padding = 1
                                ,@query_result_header = 0;
END;

DROP TABLE #CHECKDBLog;
-- END: ALERT --

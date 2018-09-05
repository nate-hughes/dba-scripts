EXECUTE AS LOGIN = 'SA';

DECLARE @recipients NVARCHAR(MAX)
       ,@subject    NVARCHAR(MAX)
       ,@body       NVARCHAR(MAX)
       ,@query      NVARCHAR(MAX)
       ,@runtime    INT          = 80000 -- 8 AM
       ,@rundate    INT;

SELECT  @rundate =
    CAST(YEAR(DATEADD(DAY, -1, GETDATE())) AS CHAR(4)) + CASE WHEN LEN(MONTH(DATEADD(DAY, -1, GETDATE()))) = 1 THEN '0'
                                                              ELSE ''
                                                         END + CAST(MONTH(DATEADD(DAY, -1, GETDATE())) AS VARCHAR(10))
    + CASE WHEN LEN(DAY(DATEADD(DAY, -1, GETDATE()))) = 1 THEN '0'
           ELSE ''
      END + CAST(DAY(DATEADD(DAY, -1, GETDATE())) AS VARCHAR(10));

SELECT  @recipients = email_address
FROM    msdb.dbo.sysoperators
WHERE   name = 'DBAs';
--SET @recipients = 'nate.hughes@morningstar.com';

SET @subject = N'SQL Agent Job Failure on ' + CONVERT(NVARCHAR(128), SERVERPROPERTY('ServerName'));

IF EXISTS(
	SELECT  j.name AS job_name
		   ,s.step_id
		   ,s.step_name
		   ,s.subsystem
		   ,s.database_name
		   ,s.command
		   ,s.last_run_outcome
		   ,h.message
	FROM    msdb.dbo.sysjobs                       j
			INNER JOIN msdb.dbo.sysjobsteps        s
				ON s.job_id = j.job_id
			LEFT OUTER JOIN msdb.dbo.sysjobhistory h
				ON  h.job_id = s.job_id
				AND h.step_id = s.step_id
	WHERE   j.enabled = 1
	AND     s.last_run_outcome = 0 -- FAILED
	AND     s.last_run_date >= @rundate
	AND     s.last_run_time >= @runtime
)
BEGIN

SET @query =
    N'set nocount on;
	SELECT	''job_name: '' + j.name
			+ char(10) + char(10) + ''step_name: '' + s.step_name
			--+ char(10) + char(10) + s.subsystem + '' : '' + coalesce(s.database_name,'''')
			+ char(10) + char(10) + ''err_msg: '' + h.message
			--,job_name = j.name
			--,s.step_id
			--,s.step_name
			--,s.subsystem
			--,s.database_name
			--,s.command
			--,s.last_run_outcome
			--,h.message
	FROM	msdb.dbo.sysjobs j
			INNER JOIN msdb.dbo.sysjobsteps s ON s.job_id = j.job_id
			LEFT OUTER JOIN msdb.dbo.sysjobhistory h
				ON h.job_id = s.job_id
				AND h.step_id = s.step_id
	WHERE	j.enabled = 1
	AND		s.last_run_outcome = 0 -- FAILED
	AND		s.last_run_date >= ' + CAST(@rundate AS VARCHAR) + N'
	AND		s.last_run_time >= ' + CAST(@runtime AS VARCHAR);
		
EXEC msdb.dbo.sp_send_dbmail @recipients = @recipients
                            ,@body = @body
                            ,@subject = @subject
                            ,@importance = 'High'
                            ,@query = @query
                            ,@query_result_header = 0;

END;

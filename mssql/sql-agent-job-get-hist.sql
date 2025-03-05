DECLARE @ShowDisabledJobs BIT = 0
       ,@ShowLastNumHours INT = NULL
       ,@ExecDateCutOff   DATETIME;

--SET @ShowLastNumHours = 24;  /* Pull just the last 24 hours */

IF @ShowLastNumHours IS NOT NULL
    SET @ExecDateCutOff = DATEADD(HOUR, -1 * @ShowLastNumHours, GETDATE());

DECLARE @jobHistory TABLE (
    job_id               UNIQUEIDENTIFIER
   ,executions           INT
   ,success              INT
   ,cancel               INT
   ,fail                 INT
   ,retry                INT
   ,last_execution_id    INT
   ,last_duration        CHAR(8)
   ,last_execution_start DATETIME
   ,avg_duration         CHAR(8)
);

WITH lastExecution AS (
    SELECT  job_id
           ,MAX(instance_id) AS last_instance_id
    FROM    msdb.dbo.sysjobhistory
    WHERE   step_id = 0
    GROUP BY job_id
)

INSERT INTO @jobHistory (
    job_id
    ,executions
    ,success
    ,cancel
    ,fail
    ,retry
    ,last_execution_id
    ,last_duration
    ,last_execution_start
    ,avg_duration
)
SELECT  sjh.job_id
       ,SUM(CASE WHEN sjh.step_id = 0 THEN 1 ELSE 0 END)                        AS executions
       ,SUM(CASE WHEN sjh.run_status = 1 AND sjh.step_id = 0 THEN 1 ELSE 0 END) AS success
       ,SUM(CASE WHEN sjh.run_status = 3 AND sjh.step_id = 0 THEN 1 ELSE 0 END) AS cancel
       ,SUM(CASE WHEN sjh.run_status = 0 AND sjh.step_id = 0 THEN 1 ELSE 0 END) AS fail
       ,SUM(CASE WHEN sjh.run_status = 2 THEN 1 ELSE 0 END)                     AS retry
       ,MAX(CASE WHEN sjh.step_id = 0 THEN sjh.instance_id ELSE NULL END)       AS last_execution_id
       ,SUBSTRING(
                     CAST(MAX(CASE WHEN le.job_id IS NOT NULL THEN sjh.run_duration ELSE NULL END) + 1000000 AS VARCHAR(7))
                    ,2, 2
                 ) + ':'
        + SUBSTRING(
                       CAST(MAX(CASE WHEN le.job_id IS NOT NULL THEN sjh.run_duration ELSE NULL END) + 1000000 AS VARCHAR(7))
                      ,4, 2
                   ) + ':'
        + SUBSTRING(
                       CAST(MAX(CASE WHEN le.job_id IS NOT NULL THEN sjh.run_duration ELSE NULL END) + 1000000 AS VARCHAR(7))
                      ,6, 2
                   )                                                            AS last_duration
       ,MAX(   CASE WHEN le.last_instance_id IS NOT NULL THEN
                        CONVERT(DATETIME, RTRIM(sjh.run_date))
                        + ((sjh.run_time / 10000 * 3600) + ((sjh.run_time % 10000) / 100 * 60) + (sjh.run_time % 10000)
                           % 100
                          ) / (86399.9964)
                    ELSE '1900-01-01'
               END
           )                                                                    AS last_execution_start
       ,SUBSTRING(CAST(AVG(sjh.run_duration) + 1000000 AS VARCHAR(7)), 2, 2) + ':'
        + SUBSTRING(CAST(AVG(sjh.run_duration) + 1000000 AS VARCHAR(7)), 4, 2) + ':'
        + SUBSTRING(CAST(AVG(sjh.run_duration) + 1000000 AS VARCHAR(7)), 6, 2)  AS avg_duration
FROM    msdb.dbo.sysjobhistory  AS sjh
        LEFT JOIN lastExecution AS le
            ON  sjh.job_id = le.job_id
            AND sjh.instance_id = le.last_instance_id
GROUP BY sjh.job_id;
 
/* We need to parse the schedule into something we can understand */
DECLARE @weekDay TABLE (mask INT, maskValue VARCHAR(32));
 
INSERT INTO @weekDay
SELECT  1,'Su'
UNION ALL
SELECT  2,'M'
UNION ALL
SELECT  4,'Tu'
UNION ALL
SELECT  8,'W'
UNION ALL
SELECT  16,'Th'
UNION ALL
SELECT  32,'F'
UNION ALL
SELECT  64,'Sa';
 
 
/* Now let's get our schedule information */
WITH myCTE AS (
    SELECT  sched.name                                                                                     AS scheduleName
           ,sched.schedule_id
           ,jobsched.job_id
           ,CASE WHEN sched.freq_type = 1 THEN 'Once'
                 WHEN sched.freq_type = 4
                 AND  sched.freq_interval = 1 THEN 'Daily'
                 WHEN sched.freq_type = 4 THEN 'Every ' + CAST(sched.freq_interval AS VARCHAR(5)) + ' days'
                 WHEN sched.freq_type = 8 THEN
                     REPLACE(
                                REPLACE(REPLACE((
                                                    SELECT      x.maskValue
                                                    FROM    @weekDay AS x
                                                    WHERE sched.freq_interval & x.mask <> 0
                                                    ORDER BY mask
                                                    FOR XML RAW
                                                ), '"/><row maskValue="', ', '
                                               ), '<row maskValue="', ''
                                       ), '"/>', ''
                            )
                     + CASE WHEN  sched.freq_recurrence_factor <> 0
                            AND   sched.freq_recurrence_factor = 1 THEN '; wkly'
                            WHEN sched.freq_recurrence_factor <> 0 THEN
                                '; every ' + CAST(sched.freq_recurrence_factor AS VARCHAR(10)) + ' wks'
                       END
                 WHEN sched.freq_type = 16 THEN
                     'On day ' + CAST(sched.freq_interval AS VARCHAR(10)) + ' of every '
                     + CAST(sched.freq_recurrence_factor AS VARCHAR(10)) + ' months'
                 WHEN sched.freq_type = 32 THEN
                     CASE WHEN sched.freq_relative_interval = 1 THEN '1st'
                          WHEN sched.freq_relative_interval = 2 THEN '2nd'
                          WHEN sched.freq_relative_interval = 4 THEN '3rd'
                          WHEN sched.freq_relative_interval = 8 THEN '4th'
                          WHEN sched.freq_relative_interval = 16 THEN 'Last'
                     END + CASE WHEN sched.freq_interval = 1 THEN ' Su'
                                WHEN sched.freq_interval = 2 THEN ' M'
                                WHEN sched.freq_interval = 3 THEN ' Tu'
                                WHEN sched.freq_interval = 4 THEN ' W'
                                WHEN sched.freq_interval = 5 THEN ' Th'
                                WHEN sched.freq_interval = 6 THEN ' F'
                                WHEN sched.freq_interval = 7 THEN ' Sa'
                                WHEN sched.freq_interval = 8 THEN ' Day'
                                WHEN sched.freq_interval = 9 THEN ' Wkday'
                                WHEN sched.freq_interval = 10 THEN ' Wkend'
                           END
                     + CASE WHEN sched.freq_recurrence_factor <> 0
                            AND  sched.freq_recurrence_factor = 1 THEN '; monthly'
                            WHEN sched.freq_recurrence_factor <> 0 THEN
                                '; every ' + CAST(sched.freq_recurrence_factor AS VARCHAR(10)) + ' months'
                       END
                 WHEN sched.freq_type = 64 THEN 'StartUp'
                 WHEN sched.freq_type = 128 THEN 'Idle'
            END                                                                                            AS frequency
           ,ISNULL(
                      'Every ' + CAST(sched.freq_subday_interval AS VARCHAR(10))
                      + CASE WHEN sched.freq_subday_type = 2 THEN ' secs'
                             WHEN sched.freq_subday_type = 4 THEN ' mins'
                             WHEN sched.freq_subday_type = 8 THEN ' hrs'
                        END, 'Once'
                  )                                                                                        AS subFrequency
           ,REPLICATE('0', 6 - LEN(sched.active_start_time)) + CAST(sched.active_start_time AS VARCHAR(6)) AS startTime
           ,REPLICATE('0', 6 - LEN(sched.active_end_time)) + CAST(sched.active_end_time AS VARCHAR(6))     AS endTime
           ,REPLICATE('0', 6 - LEN(jobsched.next_run_time)) + CAST(jobsched.next_run_time AS VARCHAR(6))   AS nextRunTime
           ,CAST(jobsched.next_run_date AS CHAR(8))                                                        AS nextRunDate
    FROM    msdb.dbo.sysschedules         AS sched
            JOIN msdb.dbo.sysjobschedules AS jobsched
                ON sched.schedule_id = jobsched.schedule_id
    WHERE   sched.enabled = 1
)

/* Finally, let's look at our actual jobs and tie it all together */
SELECT  CONVERT(NVARCHAR(128), SERVERPROPERTY('Servername'))                                               AS serverName
       ,job.job_id                                                                                         AS jobID
       ,job.name                                                                                           AS jobName
       ,CASE WHEN job.enabled = 1 THEN 'Enabled'
             ELSE 'Disabled'
        END                                                                                                AS jobStatus
       ,COALESCE(sched.scheduleName, '(unscheduled)')                                                      AS scheduleName
       ,COALESCE(sched.frequency, '')                                                                      AS frequency
       ,COALESCE(sched.subFrequency, '')                                                                   AS subFrequency
       ,COALESCE(
                    SUBSTRING(sched.startTime, 1, 2) + ':' + SUBSTRING(sched.startTime, 3, 2) + ' - '
                    + SUBSTRING(sched.endTime, 1, 2) + ':' + SUBSTRING(sched.endTime, 3, 2), ''
                )                                                                                          AS scheduleTime -- HH:MM
       ,COALESCE(
                    SUBSTRING(sched.nextRunDate, 1, 4) + '/' + SUBSTRING(sched.nextRunDate, 5, 2) + '/'
                    + SUBSTRING(sched.nextRunDate, 7, 2) + ' ' + SUBSTRING(sched.nextRunTime, 1, 2) + ':'
                    + SUBSTRING(sched.nextRunTime, 3, 2), ''
                )                                                                                          AS nextRunDate
       /* Note: the sysjobschedules table refreshes every 20 min, so nextRunDate may be out of date */
       ,COALESCE(jh.executions, 0)                                                                         AS executions
       ,COALESCE(jh.success, 0)                                                                            AS success
       ,COALESCE(jh.cancel, 0)                                                                             AS cancel
       ,COALESCE(jh.fail, 0)                                                                               AS fail
       ,COALESCE(jh.retry, 0)                                                                              AS retry
       ,COALESCE(jh.last_execution_id, 0)                                                                  AS lastExecutionID
       ,jh.last_execution_start                                                                            AS lastExecutionStart
       ,COALESCE(jh.last_duration, '00:00:01')                                                             AS lastDuration
       ,COALESCE(jh.avg_duration, '00:00:01')                                                              AS avgDuration
       ,'EXECUTE msdb.dbo.sp_update_job @job_id = ''' + CAST(job.job_id AS CHAR(36)) + ''', @enabled = 0;' AS disableSQLScript
FROM    msdb.dbo.sysjobs      AS job
        LEFT JOIN myCTE       AS sched
            ON job.job_id = sched.job_id
        LEFT JOIN @jobHistory AS jh
            ON job.job_id = jh.job_id
WHERE   (
            CASE WHEN @ShowDisabledJobs = 0 THEN 1
            END = job.enabled
      OR    @ShowDisabledJobs = 1
        )
AND     (jh.last_execution_start >= @ExecDateCutOff OR  @ExecDateCutOff IS NULL)
ORDER BY job.name
        ,jh.last_execution_start;
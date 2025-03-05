/*=============================================
  File: long_running_jobs.sql

  Author: Thomas LaRock, https://thomaslarock.com/contact-me/
  https://thomaslarock.com/2014/08/find-currently-running-long-sql-agent-jobs/

  Summary: This script will check to see if any currently
                        running jobs are running long. 

  Variables:
    @MinHistExecutions - Minimum number of job executions we want to consider 
    @MinAvgSecsDuration - Threshold for minimum job duration we care to monitor
    @HistoryStartDate - Start date for historical average
    @HistoryEndDate - End date for historical average

  These variables allow for us to control a couple of factors. First
  we can focus on jobs that are running long enough on average for
  us to be concerned with (say, 30 seconds or more). Second, we can
  avoid being alerted by jobs that have run so few times that the
  average and standard deviations are not quite stable yet. This script
  leaves these variables at 1.0, but I would advise you alter them
  upwards after testing.

  Returns: One result set containing a list of jobs that
  are currently running and are running longer than two standard deviations 
  away from their historical average. The "Min Threshold" column
  represents the average plus two standard deviations. 

  Date: August 19th, 2014

  SQL Server Versions: SQL2005, SQL2008, SQL2008R2, SQL2012, SQL2014

  You may alter this code for your own purposes. You may republish
  altered code as long as you give due credit. 

  THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY
  OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
  LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR
  FITNESS FOR A PARTICULAR PURPOSE.

=============================================*/

DECLARE   @HistoryStartDate datetime 
  ,@HistoryEndDate datetime  
  ,@MinHistExecutions int   
  ,@MinAvgSecsDuration int  

SET @HistoryStartDate = '19000101'
SET @HistoryEndDate = GETDATE()
SET @MinHistExecutions = 1.0
SET @MinAvgSecsDuration = 1.0

DECLARE @currently_running_jobs TABLE (
    job_id UNIQUEIDENTIFIER NOT NULL
    ,last_run_date INT NOT NULL
    ,last_run_time INT NOT NULL
    ,next_run_date INT NOT NULL
    ,next_run_time INT NOT NULL
    ,next_run_schedule_id INT NOT NULL
    ,requested_to_run INT NOT NULL
    ,request_source INT NOT NULL
    ,request_source_id SYSNAME NULL
    ,running INT NOT NULL
    ,current_step INT NOT NULL
    ,current_retry_attempt INT NOT NULL
    ,job_state INT NOT NULL
    ) 

--capture details on jobs
INSERT INTO @currently_running_jobs
EXECUTE master.dbo.xp_sqlagent_enum_jobs 1,''

;WITH JobHistData AS
(
  SELECT job_id
        ,date_executed=msdb.dbo.agent_datetime(run_date, run_time)
        ,secs_duration=run_duration/10000*3600
                      +run_duration%10000/100*60
                      +run_duration%100
  FROM msdb.dbo.sysjobhistory
  WHERE step_id = 0   --Job Outcome
  AND run_status = 1  --Succeeded
)
,JobHistStats AS
(
  SELECT job_id
        ,AvgDuration = AVG(secs_duration*1.)
        ,AvgPlus2StDev = AVG(secs_duration*1.) + 2*stdevp(secs_duration)
  FROM JobHistData
  WHERE date_executed >= DATEADD(day, DATEDIFF(day,'19000101',@HistoryStartDate),'19000101')
  AND date_executed < DATEADD(day, 1 + DATEDIFF(day,'19000101',@HistoryEndDate),'19000101') GROUP BY job_id HAVING COUNT(*) >= @MinHistExecutions
  AND AVG(secs_duration*1.) >= @MinAvgSecsDuration
)
SELECT jd.job_id
      ,j.name AS [JobName]
      ,MAX(act.start_execution_date) AS [ExecutionDate]
      ,AvgDuration AS [Historical Avg Duration (secs)]
      ,AvgPlus2StDev AS [Min Threshhold (secs)]
FROM JobHistData jd
JOIN JobHistStats jhs on jd.job_id = jhs.job_id
JOIN msdb..sysjobs j on jd.job_id = j.job_id
JOIN @currently_running_jobs crj ON crj.job_id = jd.job_id
JOIN msdb..sysjobactivity AS act ON act.job_id = jd.job_id
AND act.stop_execution_date IS NULL
AND act.start_execution_date IS NOT NULL
WHERE DATEDIFF(SS, act.start_execution_date, GETDATE()) > AvgPlus2StDev
AND crj.job_state = 1 -- comment this line if you want to report on all jobs
GROUP BY jd.job_id, j.name, AvgDuration, AvgPlus2StDev
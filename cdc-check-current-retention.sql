SET NOCOUNT ON;
 
DECLARE @cdcInfo TABLE (DatabaseName sysname, MinLSNTime datetime2, MaxLSNTime datetime2);
 
DECLARE @command varchar(1000);

SELECT @command = 'IF ''?'' NOT IN(''master'', ''model'', ''msdb'', ''tempdb'') BEGIN USE ?

IF (select is_cdc_enabled from sys.databases where [name] = ''?'') = 1 BEGIN

       DECLARE @cdcList TABLE (TableName NVARCHAR(128) PRIMARY KEY CLUSTERED, MinLSNTime datetime2);

       DECLARE @cdcTable NVARCHAR(128);

       INSERT @cdcList (TableName, MinLSNTime)
       SELECT
              capture_instance
              , sys.fn_cdc_map_lsn_to_time(sys.fn_cdc_get_min_lsn(capture_instance))
       FROM cdc.change_tables;

       SELECT
       DatabaseName = DB_NAME()
        , MinLSNTime = (SELECT MIN(MinLSNTime) FROM @cdcList WHERE MinLSNTime IS NOT NULL)
       , MaxLSNTime = sys.fn_cdc_map_lsn_to_time(sys.fn_cdc_get_max_lsn())
 
        END;
END' ;

INSERT @cdcInfo (DatabaseName, MinLSNTime, MaxLSNTime)
EXECUTE master.sys.sp_MSforeachdb @command;

SELECT DatabaseName, MinLSNTime, MaxLSNTime, DATEDIFF(DAY,MinLSNTime,MaxLSNTime) AS DayDiff
FROM @cdcInfo
ORDER BY DatabaseName;

SELECT sj.name, (cdc.[retention])/((60*24)) AS Default_Retention_days
FROM msdb.dbo.cdc_jobs cdc
	JOIN msdb.dbo.sysjobs sj ON cdc.job_id = sj.job_id
WHERE cdc.job_type = 'cleanup';
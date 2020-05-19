DECLARE @WaitType1 NVARCHAR(128) = N'WaitTypeName'
		,@WaitType2 NVARCHAR(128) = N'WaitTypeName';

SELECT  wait_type
        ,wait_time_ms / 1000.0                            AS Wait_Sec
        ,(wait_time_ms - signal_wait_time_ms) / 1000.0    AS Resource_Sec
        ,signal_wait_time_ms / 1000.0                     AS Signal_Sec
        ,waiting_tasks_count                              AS Wait_Count
        --,100.0 * wait_time_ms / SUM(wait_time_ms) OVER () AS Percentage
        ,ROW_NUMBER() OVER (ORDER BY wait_time_ms DESC)   AS RowNum
FROM    sys.dm_os_wait_stats
WHERE   (@WaitType1 IS NOT NULL and wait_type = @WaitType1)
OR		(@WaitType2 IS NOT NULL AND wait_type = @WaitType2);

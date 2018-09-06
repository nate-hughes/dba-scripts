SELECT  CASE WHEN t2.cntr_value = 0 THEN 0
             ELSE CONVERT(DECIMAL(38, 2), CAST(t1.cntr_value AS FLOAT) / CAST(t2.cntr_value AS FLOAT) * 100.0)
        END AS [Buffer Cache Hit Ratio (%)]
FROM    sys.dm_os_performance_counters            t1
        INNER JOIN sys.dm_os_performance_counters t2
            ON t1.object_name = t2.object_name
WHERE   t1.object_name LIKE '%Buffer Manager%'
AND     t1.counter_name = 'Buffer cache hit ratio'
AND     t2.counter_name = 'Buffer cache hit ratio base';
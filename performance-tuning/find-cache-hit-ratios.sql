DECLARE @PERF_LARGE_RAW_FRACTION INT = 537003264
       ,@PERF_LARGE_RAW_BASE     INT = 1073939712;

SELECT  dopc_fraction.object_name   AS [Performance object]
       ,dopc_fraction.instance_name AS [Counter instance]
       ,dopc_fraction.counter_name  AS [Counter name]
       --when divisor is 0, return I return NULL to indicate
       --divide by 0/no values captured
       ,CONVERT(   DECIMAL(38, 2), CAST(dopc_fraction.cntr_value AS FLOAT) / CAST(CASE dopc_base.cntr_value
                                                                                       WHEN 0 THEN NULL
                                                                                       ELSE dopc_base.cntr_value
                                                                                  END AS FLOAT)
               )                    AS Value
FROM    sys.dm_os_performance_counters      AS dopc_base
        JOIN sys.dm_os_performance_counters AS dopc_fraction
            ON  dopc_base.cntr_type = @PERF_LARGE_RAW_BASE
            AND dopc_fraction.cntr_type = @PERF_LARGE_RAW_FRACTION
            AND dopc_base.object_name = dopc_fraction.object_name
            AND dopc_base.instance_name = dopc_fraction.instance_name
            AND (
                    REPLACE(UPPER(dopc_base.counter_name), 'BASE', '') = UPPER(dopc_fraction.counter_name)
              --Worktables From Cache has "odd" name where
              --Ratio was left off
              OR    REPLACE(UPPER(dopc_base.counter_name), 'BASE', '') = REPLACE(
                                                                                    UPPER(dopc_fraction.counter_name)
                                                                                   ,'RATIO', ''
                                                                                )
                )
ORDER BY dopc_fraction.object_name
        ,dopc_fraction.instance_name
        ,dopc_fraction.counter_name;

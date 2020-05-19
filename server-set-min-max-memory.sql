/*
https://straightpathsql.com/archives/2017/02/sql-server-max-memory-best-practices/
*/

DECLARE @AvailableMemory_MB INT
       ,@MaxMemory_MB       INT
       ,@MinMemory_MB       INT
	   ,@AvailableMemory_GB INT;

SELECT  @AvailableMemory_MB = physical_memory_kb / 1024
		,@AvailableMemory_GB = physical_memory_kb / 1024 / 1024
FROM    master.sys.dm_os_sys_info;

SELECT  @MaxMemory_MB = CAST(value_in_use AS INT)
FROM    sys.configurations
WHERE   name = 'Max Server Memory (MB)';

SELECT  @MinMemory_MB = CAST(value_in_use AS INT)
FROM    sys.configurations
WHERE   name = 'Min Server Memory (MB)';

/*
A more accurate calculation as memory increases could be something around 1-2GB for the OS, plus 1GB for every 4GB up to 16GB,
then 1GB or so for every 8. For 128GB that would end up being 2 (base) + 4 (1 for every four up to 16) + 14 (1 for every 8 between
16 and 128) or 20GB. 10% would be 12% free, 20% would be 24% free. So you can use a calculation like that but I find that 10-20%
range works then watch and tweak if and as needed with data from your environment.  So if we go with that 20GB free that means we’d
want to leave 108GB for SQL Server max. That works. It’s divisible by the NUMA nodes. So I’d want to set that number to 108GB, but
the setting is in MB. So I multiple 108 * 1,024 (MB per GB) and get 110,592MB.
*/

SELECT  @AvailableMemory_MB                           AS AvailableMemory_MB
       ,@MinMemory_MB                                 AS ConfigMinMemory_MB
       ,CEILING(@AvailableMemory_GB * 1.0 / 2) * 1024 AS CalcMinMemory_MB
       ,@MaxMemory_MB                                 AS ConfigMaxMemory_MB
       ,(@AvailableMemory_GB - (2 /*OS*/
                                + CASE WHEN @AvailableMemory_GB > 16 THEN 4
                                       ELSE (@AvailableMemory_GB / 4)
                                  END /*plus 1GB for every 4GB up to 16GB*/
                                + CASE WHEN @AvailableMemory_GB > 16 THEN ((@AvailableMemory_GB - 16) / 8)
                                       ELSE 0
                                  END /*plus 1GB for every 8GB beyond 16GB*/
                               )
        ) * 1024                                      AS CalcMaxMemory_MB;


/*
EXEC SP_CONFIGURE 'Min Server Memory' , 110592
GO
EXEC SP_CONFIGURE 'Max Server Memory' , 17408
GO
RECONFIGURE
GO
*/
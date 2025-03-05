-- Enable and configure Query Store

USE [master];
GO
ALTER DATABASE [DatabaseName] 
	SET QUERY_STORE = ON;
GO
ALTER DATABASE [DatabaseName] 
	SET QUERY_STORE (                           -- DEFAULTS
		OPERATION_MODE = READ_WRITE
		,MAX_STORAGE_SIZE_MB = 1000             -- 1000 starting with SQL Server 2019 (15.x), previously 100
		,INTERVAL_LENGTH_MINUTES = 60           -- 60
		,CLEANUP_POLICY = (
			STALE_QUERY_THRESHOLD_DAYS = 30     -- 30
		) 
		,SIZE_BASED_CLEANUP_MODE = AUTO         -- AUTO
		,QUERY_CAPTURE_MODE = AUTO              -- AUTO starting with SQL Server 2019 (15.x), previously ALL
		,DATA_FLUSH_INTERVAL_SECONDS = 900      -- 900
		,MAX_PLANS_PER_QUERY = 200              -- 200
		,WAIT_STATS_CAPTURE_MODE = ON           -- ON
	);
GO

/*
Configure the max degree of parallelism Server Configuration Option
https://docs.microsoft.com/en-US/sql/database-engine/configure-windows/configure-the-max-degree-of-parallelism-server-configuration-option?view=sql-server-ver15
*/

SELECT	Configured_MAXDOP = value
FROM	sys.configurations
WHERE	name = 'max degree of parallelism';
GO

DECLARE @NumaNodes INT
		,@numberOfCores INT
		,@Rec_MAXDOP SMALLINT;

SELECT	 @NumaNodes = COUNT(*)
		,@numberOfCores = MAX(online_scheduler_count)
FROM	sys.dm_os_nodes 
WHERE node_id <> 64; --Excluded DAC node

IF @NumaNodes = 1
-- Server with single NUMA node
BEGIN
	IF @numberOfCores <= 8
		-- Less than or equal to 8 logical processors
		-- Keep MAXDOP at or below # of logical processors
		SET @Rec_MAXDOP = @numberOfCores
	ELSE
		-- Greater than 8 logical processors
		-- Keep MAXDOP at 8
		SET @Rec_MAXDOP = 8
END
ELSE
-- Server with multiple NUMA nodes
BEGIN
	IF @numberOfCores <= 16
		-- Less than or equal to 16 logical processors per NUMA node
		-- Keep MAXDOP at or below # of logical processors per NUMA node
		SET @Rec_MAXDOP = @numberOfCores
	ELSE
	BEGIN
		-- Greater than 16 logical processors per NUMA node
		-- Keep MAXDOP at half the number of logical processors per NUMA node with a MAX value of 16
		IF @numberOfCores > 16
			SET @Rec_MAXDOP = 16
		ELSE
			SET @Rec_MAXDOP = @numberOfCores
	END
END

SELECT	Recommended_MAXDOP = @Rec_MAXDOP;

/*
EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'max degree of parallelism', N'8'
GO
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'show advanced options', N'0'  RECONFIGURE WITH OVERRIDE
GO
*/


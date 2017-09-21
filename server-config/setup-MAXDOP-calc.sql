SELECT	Config_MAXDOP = value
FROM	sys.configurations
WHERE	name = 'max degree of parallelism';
GO

DECLARE @HyperThreading BIT = 1 -- assume hyperthreading on
		, @Rec_MAXDOP SMALLINT;

DECLARE @CPUs TABLE (
	NUMA_node INT
	, CPUs SMALLINT
);

INSERT INTO @CPUs (NUMA_node, CPUs)
SELECT	parent_node_id
		, COUNT(cpu_id)
FROM	sys.dm_os_schedulers
WHERE	[status] = 'VISIBLE ONLINE'
GROUP BY parent_node_id;

IF (SELECT SUM(CPUs) FROM @CPUs) > 8
	SET @Rec_MAXDOP = 8;
ELSE IF @HyperThreading = 1
	SELECT	@Rec_MAXDOP = MIN(CPUs) / 2
	FROM	@CPUs;
ELSE
	SELECT	@Rec_MAXDOP = MIN(CPUs)
	FROM	@CPUs;

SELECT	Rec_MAXDOP = @Rec_MAXDOP;

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


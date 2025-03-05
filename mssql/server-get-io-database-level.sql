/*
NOTE: sys.dm_io_virtual_file_stats counters are reset whenever the SQL Server service is started
*/

WITH AggregateIOStatistics AS (
	SELECT	DB_NAME(database_id) AS [DB Name]
			,CAST(SUM(num_of_bytes_read)/1048576 AS DECIMAL(12, 2)) AS reads_in_mb
			,CAST(SUM(num_of_bytes_written)/1048576 AS DECIMAL(12, 2)) AS writes_in_mb
			,CAST(SUM(num_of_bytes_read + num_of_bytes_written)/1048576 AS DECIMAL(12, 2)) AS io_in_mb
	FROM	sys.dm_io_virtual_file_stats(NULL, NULL) AS [DM_IO_STATS]
	GROUP BY database_id
)
SELECT	ROW_NUMBER() OVER(ORDER BY io_in_mb DESC) AS [I/O Rank]
		,[DB Name]
		,CAST(reads_in_mb/ SUM(reads_in_mb) OVER() * 100.0 AS DECIMAL(5,2)) AS [Read Percent]
		,reads_in_mb AS [Read I/O (MB)]
		,CAST(writes_in_mb/ SUM(writes_in_mb) OVER() * 100.0 AS DECIMAL(5,2)) AS [Write Percent]
		,writes_in_mb AS [Write I/O (MB)]
		,CAST(io_in_mb/ SUM(io_in_mb) OVER() * 100.0 AS DECIMAL(5,2)) AS [I/O Percent]
		,io_in_mb AS [Total I/O (MB)]
FROM	AggregateIOStatistics
ORDER BY [I/O Rank];

 
SELECT	DB_NAME(DB_ID()) AS [DB_Name]
		,DFS.name AS [Logical_Name]
		,DIVFS.[file_id]
		,DFS.physical_name AS [PH_Name]
		,DIVFS.num_of_reads
		,DIVFS.io_stall_read_ms
		,CAST(100. * DIVFS.io_stall_read_ms/(DIVFS.io_stall_read_ms + DIVFS.io_stall_write_ms) AS DECIMAL(10,1)) AS [IO_Stall_Reads_Pct]
		,CAST(DIVFS.num_of_bytes_read/1048576.0 AS DECIMAL(19, 2)) AS [MB Read]
		,CAST(100. * DIVFS.num_of_reads/(DIVFS.num_of_reads + DIVFS.num_of_writes) AS DECIMAL(10,1)) AS [# Reads Pct]
		,CAST(100. * DIVFS.num_of_bytes_read/(DIVFS.num_of_bytes_read + DIVFS.num_of_bytes_written) AS DECIMAL(10,1)) AS [Read Bytes Pct]
		,DIVFS.num_of_writes
		,DIVFS.io_stall_write_ms
		,CAST(100. * DIVFS.io_stall_write_ms/(DIVFS.io_stall_write_ms + DIVFS.io_stall_read_ms) AS DECIMAL(10,1)) AS [IO_Stall_Writes_Pct]
		,CAST(DIVFS.num_of_bytes_written/1048576.0 AS DECIMAL(19, 2)) AS [MB Written]
		,CAST(100. * DIVFS.num_of_writes/(DIVFS.num_of_reads + DIVFS.num_of_writes) AS DECIMAL(10,1)) AS [# Write Pct]
		,CAST(100. * DIVFS.num_of_bytes_written/(DIVFS.num_of_bytes_read + DIVFS.num_of_bytes_written) AS DECIMAL(10,1)) AS [Written Bytes Pct]
		,(DIVFS.num_of_reads + DIVFS.num_of_writes) AS [Writes + Reads]
FROM	sys.dm_io_virtual_file_stats(DB_ID(), NULL) AS DIVFS
		JOIN sys.database_files AS DFS WITH (NOLOCK) ON DIVFS.[file_id]= DFS.[file_id]
ORDER BY (DIVFS.num_of_reads + DIVFS.num_of_writes) DESC;

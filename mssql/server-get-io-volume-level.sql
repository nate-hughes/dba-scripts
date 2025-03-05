/*
If you ask SQLskills, we will tell you something along the lines of:
	Excellent: < 1ms
	Very good: < 5ms
	Good: 5 – 10ms
	Poor: 10 – 20ms
	Bad: 20 – 100ms
	Really bad: 100 – 500ms
	OMG!: > 500ms

If you are finding that read and write latencies are bad on your server, there are several places you can start looking for issues. This is not a comprehensive list but some guidance of where to start.
- Analyze your workload. Is your indexing strategy correct? Not having the proper indexes will lead to much more data being read from disk. Scans instead of seeks.
- Are your statistics up to date? Bad statistics can make for poor choices for execution plans.
- Do you have parameter sniffing issues that are causing poor execution plans?
- Is the buffer pool under memory pressure, for instance from a bloated plan cache?
- Any network issues? Is your SAN fabric performing correctly? Have your storage engineer validate pathing and network.
- Move the hot spots to different storage arrays. In some cases it may be a single database or just a few databases that are causing all the problems. Isolating them to a different set of disk, or faster high end disk such as SSD’s may be the best logical solution.
- Can you partition the database to move troublesome tables to different disk to spread the load?
*/

CREATE TABLE #DiskInformation (
	DISK_Drive CHAR(100)
	,DISK_num_of_reads BIGINT
	,DISK_io_stall_read_ms BIGINT
	,DISK_num_of_writes BIGINT
	,DISK_io_stall_write_ms BIGINT
	,DISK_num_of_bytes_read BIGINT
	,DISK_num_of_bytes_written BIGINT
	,DISK_io_stall BIGINT
);
 
INSERT #DiskInformation (DISK_Drive, DISK_num_of_reads, DISK_io_stall_read_ms, DISK_num_of_writes, DISK_io_stall_write_ms, DISK_num_of_bytes_read, DISK_num_of_bytes_written, DISK_io_stall)
SELECT	LEFT(UPPER(mf.physical_name), 2) AS DISK_Drive
		,SUM(num_of_reads) AS DISK_num_of_reads
		,SUM(io_stall_read_ms) AS DISK_io_stall_read_ms
		,SUM(num_of_writes) AS DISK_num_of_writes
		,SUM(io_stall_write_ms) AS DISK_io_stall_write_ms
		,SUM(num_of_bytes_read) AS DISK_num_of_bytes_read
		,SUM(num_of_bytes_written) AS DISK_num_of_bytes_written
		,SUM(io_stall) AS io_stall
FROM	sys.dm_io_virtual_file_stats(NULL, NULL) AS vfs
		INNER JOIN sys.master_files AS mf WITH (NOLOCK)
			ON vfs.database_id = mf.database_id AND vfs.file_id = mf.file_id
GROUP BY LEFT(UPPER(mf.physical_name), 2);
 
SELECT	DISK_Drive
		,CASE 
			WHEN DISK_num_of_reads = 0 THEN 0 
			ELSE (DISK_io_stall_read_ms/DISK_num_of_reads) 
		END AS [Read Latency]
		,CASE 
			WHEN DISK_io_stall_write_ms = 0 THEN 0 
			ELSE (DISK_io_stall_write_ms/DISK_num_of_writes) 
		END AS [Write Latency]
		,CASE 
			WHEN (DISK_num_of_reads = 0 AND DISK_num_of_writes = 0) THEN 0 
			ELSE (DISK_io_stall/(DISK_num_of_reads + DISK_num_of_writes)) 
		END AS [Overall Latency]
		,CASE 
			WHEN DISK_num_of_reads = 0 THEN 0 
			ELSE (DISK_num_of_bytes_read/DISK_num_of_reads) 
		END AS [Avg Bytes/Read]
		,CASE 
			WHEN DISK_io_stall_write_ms = 0 THEN 0 
			ELSE (DISK_num_of_bytes_written/DISK_num_of_writes) 
		END AS [Avg Bytes/Write]
		,CASE 
			WHEN (DISK_num_of_reads = 0 AND DISK_num_of_writes = 0) THEN 0 
			ELSE ((DISK_num_of_bytes_read + DISK_num_of_bytes_written)/(DISK_num_of_reads + DISK_num_of_writes)) 
		END AS [Avg Bytes/Transfer]
from	#DiskInformation
ORDER BY [Overall Latency] OPTION (RECOMPILE);

DROP TABLE IF EXISTS #DiskInformation;

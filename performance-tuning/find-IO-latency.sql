SELECT
    --virtual file latency
    CASE WHEN vfs.num_of_reads = 0 THEN 0
         ELSE (vfs.io_stall_read_ms / vfs.num_of_reads)
    END                       AS ReadLatency
   ,CASE WHEN vfs.io_stall_write_ms = 0 THEN 0
         ELSE (vfs.io_stall_write_ms / vfs.num_of_writes)
    END                       AS WriteLatency
   ,CASE WHEN (vfs.num_of_reads = 0 AND vfs.num_of_writes = 0) THEN 0
         ELSE (vfs.io_stall / (vfs.num_of_reads + vfs.num_of_writes))
    END                       AS Latency
   --avg bytes per IOP
   ,CASE WHEN vfs.num_of_reads = 0 THEN 0
         ELSE (vfs.num_of_bytes_read / vfs.num_of_reads)
    END                       AS AvgBPerRead
   ,CASE WHEN vfs.io_stall_write_ms = 0 THEN 0
         ELSE (vfs.num_of_bytes_written / vfs.num_of_writes)
    END                       AS AvgBPerWrite
   ,CASE WHEN (vfs.num_of_reads = 0 AND vfs.num_of_writes = 0) THEN 0
         ELSE ((vfs.num_of_bytes_read + vfs.num_of_bytes_written) / (vfs.num_of_reads + vfs.num_of_writes))
    END                       AS AvgBPerTransfer
   ,LEFT(mf.physical_name, 2) AS Drive
   ,DB_NAME(vfs.database_id)  AS DB
   --vfs.*,
   ,mf.physical_name
   ,SUBSTRING(mf.physical_name, LEN(mf.physical_name) - CHARINDEX('\', REVERSE(mf.physical_name)) + 2, 100)
FROM    sys.dm_io_virtual_file_stats(NULL, NULL) AS vfs
        JOIN sys.master_files                    AS mf
            ON  vfs.database_id = mf.database_id
            AND vfs.file_id = mf.file_id
ORDER BY Latency DESC;
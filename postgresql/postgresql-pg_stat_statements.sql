-- Top Queries by Total Execution Time
SELECT 
  calls
  ,total_exec_time AS total_time_ms
  ,mean_exec_time AS avg_time_ms
  ,query
FROM pg_stat_statements
WHERE query NOT ILIKE 'EXPLAIN%' AND query NOT ILIKE 'BEGIN%' AND query NOT ILIKE 'COMMIT%'
ORDER BY total_exec_time DESC
LIMIT 10;

-- Top Queries by Number of Executions
SELECT 
  calls
  ,total_exec_time AS total_time_ms
  ,mean_exec_time AS avg_time_ms
  ,query
FROM pg_stat_statements
WHERE query NOT ILIKE 'EXPLAIN%' AND query NOT ILIKE 'BEGIN%' AND query NOT ILIKE 'COMMIT%'
ORDER BY calls DESC
LIMIT 10;

-- Top Queries by Average Execution Time
SELECT 
  calls
  ,total_exec_time AS total_time_ms
  ,mean_exec_time AS avg_time_ms
  ,query
FROM pg_stat_statements
WHERE calls > 50  -- filter out low-frequency one-offs
AND query NOT ILIKE 'EXPLAIN%' AND query NOT ILIKE 'BEGIN%' AND query NOT ILIKE 'COMMIT%'
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Top Queries wih High Execution Time Variance 
SELECT 
    calls
    ,min_exec_time AS min_ms
    ,max_exec_time AS max_ms
    ,mean_exec_time AS avg_ms
    ,stddev_exec_time AS stddev_ms
    ,stddev_exec_time::float / NULLIF(mean_exec_time, 0) AS variance_ratio
    ,query
FROM pg_stat_statements
WHERE calls > 50  -- filter out low-frequency one-offs
and query NOT ILIKE 'EXPLAIN%' AND query NOT ILIKE 'BEGIN%' AND query NOT ILIKE 'COMMIT%'
ORDER BY variance_ratio DESC
LIMIT 10;

-- Top Queries with High Disk I/O
SELECT 
  calls
  ,mean_exec_time
  ,shared_blks_read  -- blocks read from disk (I/O)
  ,shared_blks_hit   -- blocks served from memory (cache hit)
  ,temp_blks_written -- blocks written to temporary disk space (e.g., due to sorts or hashes spilling)
  ,(shared_blks_read + temp_blks_written) AS io_impact -- sum of disk reads + temp writes (total disk pressure)
  ,shared_blks_read::float / (shared_blks_hit + shared_blks_read) * 100 AS read_percentage -- % of reads that came from disk, not cache
  ,query
FROM pg_stat_statements
WHERE shared_blks_read + shared_blks_hit > 1000 -- filter out queries with low I/O volume
AND query NOT ILIKE 'EXPLAIN%' AND query NOT ILIKE 'BEGIN%' AND query NOT ILIKE 'COMMIT%'
ORDER BY read_percentage DESC
LIMIT 10;

SELECT 
    query,
    calls,
    min_exec_time AS min_ms,
    max_exec_time AS max_ms,
    mean_exec_time AS avg_ms,
    stddev_exec_time AS stddev_ms,
    ROUND((stddev_exec_time / NULLIF(mean_exec_time, 0))::numeric, 2) AS variance_ratio
FROM pg_stat_statements
WHERE calls > 100  -- Ignore rare queries that distort variance
ORDER BY variance_ratio DESC
LIMIT 10;

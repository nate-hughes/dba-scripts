-- Display existing Indexes
SHOW INDEX FROM TableName FROM DatabaseName;
SHOW INDEX FROM TableName;

SELECT *
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_NAME = 'TableName';

-- Get Index Sizes
SELECT
  index_name,
  MAX(CASE WHEN stat_name='size' THEN stat_value END) AS pages,
  ROUND(MAX(CASE WHEN stat_name='size' THEN stat_value END) * @@innodb_page_size / 1024 / 1024, 1) AS size_mb
FROM mysql.innodb_index_stats
WHERE TABLE_NAME = 'TableName'
  -- AND INDEX_NAME IN ('PRIMARY','IndexName1','IndexName2')
GROUP BY index_name;

-- Get Index Usage
-- COUNT_FETCH: how many times rows were fetched via that index since the instance last started / counters last reset
-- NULL Index_Name: table I/O not attributed to a specific index (e.g. full table scans or table-level ops)
SELECT
  OBJECT_NAME AS TABLE_NAME,
  INDEX_NAME,
  COUNT_FETCH
FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE OBJECT_NAME = 'TableName'
ORDER BY COUNT_FETCH DESC;

-- Creating Index
-- CREATE INDEX IndexName ON TableName (ColumnName);
CREATE INDEX idx_film_length ON film (length);

-- Explain Index Usage
EXPLAIN SELECT film_id, length
FROM film
WHERE length = 100;

-- FORCE Index
EXPLAIN SELECT film_id, length 
FROM film FORCE INDEX (idx_film_length)
WHERE length = 100;

-- SUGGEST Indexes
EXPLAIN SELECT film_id, length  
FROM film USE INDEX (idx_film_length,idx_film_ColumnName)
WHERE length = 100;

-- IGNORE Indexes
EXPLAIN SELECT film_id, length  
FROM film IGNORE INDEX (idx_film_length,idx_film_ColumnName)
WHERE length = 100;

-- Dropping Index
DROP Index idx_film_length ON film;

-- UPDATE STATISTICS
ANALYZE TABLE TableName;

-- DEFRAG Index
OPTIMIZE TABLE TableName;

-- REBUILD Table (equiv to index drop & create)
ALTER TABLE TableName;



















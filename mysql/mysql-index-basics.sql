-- Display existing Indexes
SHOW INDEX FROM TableName FROM DatabaseName;
SHOW INDEX FROM TableName;

SELECT *
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_NAME = 'TableName';

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



















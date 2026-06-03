-- High-write / low-read index candidates (exclude PKs)
WITH tbl AS (
  SELECT relid,
         n_tup_ins + n_tup_upd + n_tup_del AS writes,
         n_live_tup
  FROM pg_stat_user_tables
),
idx AS (
  SELECT relid, indexrelid, idx_scan, idx_tup_read, idx_tup_fetch
  FROM pg_stat_user_indexes
)
SELECT
  i.indexrelid::regclass                AS index_name,
  c.relname                             AS table_name,
  t.writes,
  i.idx_scan                            AS reads,          -- Number of index scans initiated on this index
  i.idx_tup_read                        AS tuples_read,    -- Number of index entries returned by index scans
  i.idx_tup_fetch                       AS tuples_fetched, -- Number of live table rows fetched using this index
  pg_size_pretty(pg_relation_size(i.indexrelid)) AS index_size,
--  pg_relation_size(i.indexrelid)        AS index_bytes,
  x.indisprimary                        AS is_primary,
  x.indisunique                         AS is_unique
FROM idx i
JOIN tbl t          ON t.relid = i.relid
JOIN pg_index x     ON x.indexrelid = i.indexrelid
JOIN pg_class c     ON c.oid = i.relid
WHERE NOT x.indisprimary                  -- keep PKs
-- AND NOT x.indisunique                  -- optionally keep unique constraints
-- Schema filter
-- AND c.relnamespace = 'public'::regnamespace
-- Single table filter
AND i.relid = 'public."MarketStrategyContextSnapshot"'::regclass
ORDER BY i.idx_scan DESC, pg_relation_size(i.indexrelid) DESC;

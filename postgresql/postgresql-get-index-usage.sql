SELECT
    s.indexrelid::regclass AS index_name,
    pg_size_pretty(pg_relation_size(s.indexrelid)) AS index_size,
    s.idx_scan AS index_reads,            -- Number of index scans initiated on this index
    s.idx_tup_read AS tuples_read,        -- Number of index entries returned by index scans
    s.idx_tup_fetch AS tuples_fetched,    -- Number of live table rows fetched using this index
    i.indisunique AS is_unique,
    i.indisprimary AS is_primary
FROM
    pg_stat_user_indexes s
JOIN
    pg_index i ON s.indexrelid = i.indexrelid
WHERE
    s.relid = 'decisioning."discreteOffer"'::regclass;

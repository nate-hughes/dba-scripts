--Get distinct count
--If the table is huge and you want an estimate (very fast)
SELECT
  c.reltuples::bigint AS est_rows,
  s.n_distinct        AS est_distinct_vendor_accounts
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_stats s ON s.schemaname = n.nspname AND s.tablename = c.relname
WHERE n.nspname = 'schema'
  AND c.relname = 'table'
  AND s.attname = 'column';
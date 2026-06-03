-- Column-level stats snapshot
SELECT
  s.schemaname,
  s.tablename,
  s.attname                          AS column_name,
  round(s.null_frac::numeric,4)      AS null_frac,
  s.n_distinct,
  array_length(s.most_common_vals,1) AS mcv_count,
  s.most_common_vals,
  s.most_common_freqs,
  array_length(s.histogram_bounds,1) AS histogram_bins,
  round(s.correlation::numeric,4)    AS correlation
FROM pg_stats AS s
WHERE s.schemaname = 'public'
  AND s.tablename = 'MarketStrategyContextDecision'
ORDER BY s.tablename, s.attname;

-- How stale are stats? (percent of rows modified since last analyze)
SELECT
  schemaname,
  relname AS table_name,
  n_live_tup,
  n_dead_tup,
  n_mod_since_analyze,
  CASE
    WHEN n_live_tup > 0
    THEN round(100.0 * n_mod_since_analyze / n_live_tup, 2)
    ELSE 0
  END AS pct_modified_since_analyze,
  last_analyze,
  last_autoanalyze,
  last_vacuum,
  last_autovacuum,
  vacuum_count,
  analyze_count
FROM pg_stat_all_tables
WHERE schemaname = 'public'
  AND relname = 'MarketStrategyContextDecision'
ORDER BY pct_modified_since_analyze DESC;

-- When were stats last reset (db-wide)?
SELECT datname, stats_reset
FROM pg_stat_database
WHERE datname = current_database();

-- Current statistics targets (global & per-column)
-- Global default
SHOW default_statistics_target;

-- Per-column overrides (attstattarget = -1 means "use default")
SELECT
  n.nspname  AS schemaname,
  c.relname  AS table_name,
  a.attname  AS column_name,
  a.attstattarget
FROM pg_attribute a
JOIN pg_class     c ON c.oid = a.attrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname = 'MarketStrategyContextDecision'
  AND a.attnum > 0 AND NOT a.attisdropped
ORDER BY c.relname, a.attname;

-- Quick refresh
ANALYZE VERBOSE public."MarketStrategyContextDecision";

-- Shows table-level reloptions like autovacuum_* if set
SELECT
  n.nspname AS schemaname,
  c.relname AS table_name,
  t.*
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN LATERAL pg_options_to_table(c.reloptions) t ON true
WHERE n.nspname = 'public'
  AND c.relname = 'MarketStrategyContextDecision'
ORDER BY schemaname, table_name, t.option_name;

-- Which columns changed most since last analyze (good targets for higher stats)?
-- Heuristic: columns with small ndistinct but used in predicates may benefit from higher targets.
SELECT
  s.schemaname,
  s.tablename,
  s.attname AS column_name,
  s.n_distinct,
  round(s.null_frac::numeric,4) AS null_frac
FROM pg_stats s
JOIN pg_stat_all_tables t
  ON t.schemaname = s.schemaname AND t.relname = s.tablename
WHERE s.schemaname = 'public'
  AND s.tablename = 'MarketStrategyContextDecision'
ORDER BY s.tablename, s.n_distinct NULLS LAST, s.attname;

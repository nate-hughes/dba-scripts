SELECT
   n.nspname AS schema_name,
   t.relname AS table_name,
   i.relname AS index_name,
   a.attname AS column_name,
   ixs.indexdef
FROM
   pg_class t,
   pg_class i,
   pg_index ix,
   pg_attribute a,
   pg_namespace n,
   pg_indexes ixs
WHERE
   t.oid = ix.indrelid
   AND i.oid = ix.indexrelid
   AND a.attrelid = t.oid
   AND a.attnum = ANY(ix.indkey)
   AND t.relnamespace = n.oid
   AND n.nspname = ixs.schemaname
   AND t.relname = ixs.tablename
   AND i.relname = ixs.indexname
   AND n.nspname = 'public' -- filter on schema
   -- AND t.relname = '__tablename__' -- filter on table
ORDER BY
   n.nspname,
   t.relname,
   ix.indisprimary DESC, -- move PK to top of table indexes
   i.relname,
   a.attnum;
   
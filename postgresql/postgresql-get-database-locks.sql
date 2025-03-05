SELECT
    current_database() AS database_name,
    pg_namespace.nspname AS schema_name,
    pg_class.relname AS table_name,
    pg_locks.locktype,
    pg_locks.mode,
    pg_locks.granted
FROM
    pg_locks
JOIN
    pg_class ON pg_locks.relation = pg_class.oid
JOIN
    pg_namespace ON pg_class.relnamespace = pg_namespace.oid
WHERE
    pg_locks.locktype = 'relation'
	AND pg_namespace.nspname <> 'pg_catalog'
ORDER BY
    pg_namespace.nspname,
    pg_class.relname;


-- build ALTER SCHEMA OWNER scripts
SELECT format('ALTER SCHEMA %I OWNER TO db_owner;',ns.nspname)
	,ns.nspname
	,r.rolname
FROM pg_catalog.pg_namespace ns
	JOIN pg_roles r ON ns.nspowner = r.oid
WHERE r.rolname <> 'rds_superuser'
AND r.rolname <> 'db_owner'
AND ns.nspowner <> 10
ORDER BY ns.nspname;

-- build ALTER TABLE OWNER scripts
SELECT 'ALTER TABLE '|| schemaname || '."' || tablename ||'" OWNER TO db_owner;'
FROM pg_tables WHERE NOT schemaname IN ('pg_catalog', 'information_schema') AND schemaname = 'public'
ORDER BY schemaname, tablename;

-- build ALTER SEQUENCE OWNER scripts
SELECT 'ALTER SEQUENCE '|| sequence_schema || '."' || sequence_name ||'" OWNER TO db_owner;'
FROM information_schema.sequences WHERE NOT sequence_schema IN ('pg_catalog', 'information_schema') AND sequence_schema = 'public'
ORDER BY sequence_schema, sequence_name;

-- build ALTER VIEW OWNER scripts
SELECT 'ALTER VIEW '|| table_schema || '."' || table_name ||'" OWNER TO db_owner;'
FROM information_schema.views WHERE NOT table_schema IN ('pg_catalog', 'information_schema') AND table_schema = 'public'
ORDER BY table_schema, table_name;

-- build ALTER MATERIALIZED VIEW OWNER scripts
SELECT 'ALTER TABLE '|| oid::regclass::text ||' OWNER TO db_owner;'
FROM pg_class WHERE relkind = 'm'
ORDER BY oid;


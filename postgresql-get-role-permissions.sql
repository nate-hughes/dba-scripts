-- get table permissions
SELECT grantee, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_name='table_name'

-- get table permissions for a role
SELECT grantor, grantee, table_schema, table_name, privilege_type
FROM information_schema.table_privileges
WHERE grantee = 'readonly'
ORDER BY table_name

SELECT grantee AS user, CONCAT(table_schema, '.', table_name) AS table, 
    CASE 
        WHEN COUNT(privilege_type) = 7 THEN 'ALL'
        ELSE ARRAY_TO_STRING(ARRAY_AGG(privilege_type), ', ')
    END AS grants
FROM information_schema.role_table_grants
WHERE grantee = 'readonly'
GROUP BY table_name, table_schema, grantee
ORDER BY table_name;

-- grant SELECT permissions on tables in the public schema to a role
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;

-- get all users and roles along with roles that have been granted to them
SELECT 
      r.rolname, 
      ARRAY(SELECT b.rolname
            FROM pg_catalog.pg_auth_members m
            JOIN pg_catalog.pg_roles b ON (m.roleid = b.oid)
            WHERE m.member = r.oid) as memberof,
      r.rolsuper,
	  r.rolinherit,
	  r.rolcreaterole,
	  r.rolcreatedb,
	  r.rolcanlogin
FROM pg_catalog.pg_roles r
WHERE r.rolname NOT IN ('pg_signal_backend','rds_iam',
                        'rds_replication','rds_superuser',
						'rds_ad', 'rds_password',
                        'rdsadmin','rdsrepladmin')
AND r.rolname NOT LIKE 'pg_%'
ORDER BY 1;
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

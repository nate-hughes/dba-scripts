-- Show default privileges (ALTER DEFAULT PRIVILEGES) granted to a specified role in the current database
WITH expanded AS (
    SELECT
        COALESCE(n.nspname, '<all schemas>')        AS schema,
        CASE d.defaclobjtype
             WHEN 'r' THEN 'table'
             WHEN 'S' THEN 'sequence'
             WHEN 'f' THEN 'function'
             WHEN 'T' THEN 'type'
             WHEN 'n' THEN 'schema'
        END                                         AS object_type,
        pg_get_userbyid(d.defaclrole)              AS object_owner,
        (aclexplode(d.defaclacl)).grantee          AS grantee_oid,
        (aclexplode(d.defaclacl)).privilege_type   AS priv_type,
        (aclexplode(d.defaclacl)).is_grantable     AS is_grantable
    FROM pg_default_acl d
    LEFT JOIN pg_namespace n ON n.oid = d.defaclnamespace
)
SELECT
    schema,
    object_type,
    object_owner,
	pg_get_userbyid(grantee_oid),
    string_agg(priv_type
               || CASE WHEN is_grantable THEN ' (GRANTABLE)' ELSE '' END
               , ', ' ORDER BY priv_type)          AS privileges
FROM expanded
WHERE pg_get_userbyid(grantee_oid) = :'target_role'
GROUP BY schema, object_type, object_owner, grantee_oid
ORDER BY schema, object_type;

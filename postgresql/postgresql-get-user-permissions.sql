-- table permissions
select 
   * 
   ,'GRANT ' || privilege_type || ' ON ' || table_schema || '."' || table_name || '" TO "NEW_USER";'
from information_schema.role_table_grants 
where grantee='YOUR_USER'
;
-- ownership
select 
   * 
   ,'ALTER TABLE ' || schemaname || '."' || tablename || '" OWNER TO "NEW_OWNER";' AS changeowner
from pg_tables 
where tableowner = 'YOUR_USER'
--and tableowner != 'rdsadmin'
--and tableowner != 'db_owner';
;
SELECT 
   * 
   ,'ALTER TABLE IF EXISTS ' || schemaname || '."' || viewname || '" OWNER TO "NEW_OWNER";' AS changeowner
FROM pg_views
WHERE viewowner = 'YOUR_USER'
--and tableowner != 'rdsadmin'
--and tableowner != 'db_owner';
;
-- schema permissions
select  
  r.usename as grantor, e.usename as grantee, nspname, privilege_type, is_grantable
from pg_namespace
join lateral (
  SELECT
    *
  from
    aclexplode(nspacl) as x
) a on true
join pg_user e on a.grantee = e.usesysid
join pg_user r on a.grantor = r.usesysid 
 where e.usename = 'YOUR_USER'
;

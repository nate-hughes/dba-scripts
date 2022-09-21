-- table permissions
select 
 * 
from information_schema.role_table_grants 
where grantee='YOUR_USER'
;
-- ownership
select 
   * 
from pg_tables 
where tableowner = 'YOUR_USER'
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

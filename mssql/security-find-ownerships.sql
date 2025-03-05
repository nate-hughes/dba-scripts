-- Drop Login issues for logins tied to SQL Server Availability Groups
-- https://www.mssqltips.com/sqlservertip/5201/drop-login-issues-for-logins-tied-to-sql-server-availability-groups/

select * from sys.server_principals where name in ('emaplan\mhursh', 'emaplan\nhughes', 'emaplan\kbarrett', 'emaplan\bblackwell')
select e.*, p.name
from sys.endpoints e
left join master.sys.server_principals p on e.principal_id = p.principal_id
where e.principal_id <> 1
SELECT pm.class, pm.class_desc, pm.major_id, pm.minor_id, 
   pm.grantee_principal_id, pm.grantor_principal_id, 
   pm.[type], pm.[permission_name], pm.[state],pm.state_desc, 
   pr.[name] AS [owner], gr.[name] AS grantee
FROM sys.server_permissions pm 
   JOIN sys.server_principals pr ON pm.grantor_principal_id = pr.principal_id
   JOIN sys.server_principals gr ON pm.grantee_principal_id = gr.principal_id
WHERE pr.[name] <> 'sa' 
SELECT ag.[name] AS AG_name, ag.group_id, r.replica_id, r.owner_sid, p.[name] as owner_name 
FROM sys.availability_groups ag 
   JOIN sys.availability_replicas r ON ag.group_id = r.group_id
   JOIN sys.server_principals p ON r.owner_sid = p.[sid]
WHERE p.[name] <> 'sa'
SELECT [name] AS dbname FROM sys.databases WHERE SUSER_SNAME(owner_sid) <> 'sa'

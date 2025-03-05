/* Servers and groups */
SELECT DISTINCT
    groups.name AS 'Server Group Name'
    ,svr.server_name AS 'Server Name'
FROM msdb.dbo.sysmanagement_shared_server_groups_internal groups
    INNER JOIN msdb.dbo.sysmanagement_shared_registered_servers_internal svr
        ON groups.server_group_id = svr.server_group_id
ORDER BY groups.name
    ,svr.server_name
GO

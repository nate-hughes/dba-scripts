/*
Deploying Resource Governor Using Online Scripts
https://michaeljswart.com/2023/08/deploying-resource-governor-using-online-scripts/
*/

SELECT 
	dwg.name [current work group], 
	dwg.pool_id [current resource pool], 
	wg.name [configured work group], 
	wg.pool_id [configured resource pool],
	s.*
FROM 
	sys.dm_exec_sessions s
INNER JOIN 
	sys.dm_resource_governor_workload_groups dwg /* existing groups */
	ON dwg.group_id = s.group_id
LEFT JOIN 
	sys.resource_governor_workload_groups wg /* configured groups */
	ON wg.group_id = s.group_id
WHERE 
	isnull(wg.group_id, -1) <> dwg.pool_id
ORDER BY 
	s.session_id;

SELECT	DISTINCT
		cluster_name
FROM	sys.dm_hadr_cluster
WHERE	LEFT(cluster_name, 1) LIKE '[a-z]';


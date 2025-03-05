SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT	SCHEMA_NAME(o.schema_id) AS [Schema]
		,o.name AS [Table]
		,ISNULL(i.name,'-- HEAP --') AS [Index]
		,(COUNT(*) * 8) / 1024 AS [Buffer size(MB)]
		,COUNT(*) AS NumberOf8KPages
FROM	sys.allocation_units AS a
		INNER JOIN sys.dm_os_buffer_descriptors AS b ON a.allocation_unit_id = b.allocation_unit_id
		INNER JOIN sys.partitions AS p 
			ON a.container_id = p.hobt_id
		INNER JOIN sys.indexes i
			ON p.index_id = i.index_id
            AND p.[object_id] = i.[object_id]
		INNER JOIN sys.objects o ON i.object_id = o.object_id
WHERE	b.database_id = DB_ID()
AND		p.[object_id] > 100
GROUP BY p.[object_id]
		,o.schema_id
		,o.name
		,i.name
ORDER BY NumberOf8KPages DESC;
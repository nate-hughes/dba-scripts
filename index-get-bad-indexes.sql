SELECT	OBJECT_NAME(s.[object_id]) AS [Table Name]
		, i.name AS [Index Name]
		--, i.index_id AS [Index Id]
		, i.type_desc AS [Index Type]
		, s.user_seeks + s.user_scans + s.user_lookups AS [Total Reads]
		, s.user_updates AS [Total Writes]
		, s.user_updates - (s.user_seeks + s.user_scans + s.user_lookups) AS [Difference]
		, CASE
			WHEN s.user_updates < 1 THEN 100
			ELSE 1.00 * (s.user_seeks + s.user_scans + s.user_lookups) / s.user_updates
		  END AS reads_per_write
		, (SELECT SUM(p.rows) FROM sys.partitions p WHERE p.index_id = i.index_id AND i.object_id = p.object_id) AS [Rows]
		, CASE WHEN i.is_primary_key = 1 OR i.is_unique_constraint = 1 THEN
				'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(s.[object_id])) + '.' + QUOTENAME(OBJECT_NAME(s.[object_id]))	+ ' DROP CONSTRAINT ' + QUOTENAME(i.name)
			ELSE
				'DROP INDEX ' + QUOTENAME(i.name)	+ ' ON ' + QUOTENAME(OBJECT_SCHEMA_NAME(s.[object_id])) + '.' + QUOTENAME(OBJECT_NAME(s.[object_id]))
			END as [Drop Statement]
FROM	sys.dm_db_index_usage_stats AS s WITH (NOLOCK)
		INNER JOIN sys.indexes AS i WITH (NOLOCK)
			ON s.[object_id] = i.[object_id]
			AND i.index_id = s.index_id
WHERE	OBJECTPROPERTY(s.[object_id],'IsUserTable') = 1
AND		s.database_id = DB_ID()
AND		s.user_updates > (s.user_seeks + s.user_scans + s.user_lookups)
AND		i.index_id > 1
ORDER BY [Difference] DESC
	, [Total Writes] DESC
	, [Total Reads] ASC
OPTION (RECOMPILE);

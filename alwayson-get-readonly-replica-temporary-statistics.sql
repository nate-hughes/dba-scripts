USE tempdb;
GO

SELECT	OBJECT_NAME(s.object_id) AS ObjectName
		,COL_NAME(sc.object_id, sc.column_id) AS ColumnName
		,s.name AS StatisticsName
FROM	sys.stats s
		JOIN sys.stats_columns sc ON s.stats_id = sc.stats_id AND s.object_id = sc.object_id
WHERE	s.is_temporary <> 0
ORDER BY s.name;

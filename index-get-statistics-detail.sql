USE [DBName];

-- whats stats exist for the table
--EXEC sp_helpstats @objname = 'User';
SELECT	o.name AS TblName
		,s.name AS StatName
		,s.stats_id
		,sc.stats_column_id
		,c.name AS ColName
		,s.auto_created
		,s.filter_definition
		,sp.last_updated
		,sp.rows
		,sp.rows_sampled
		,sp.steps
		,sp.modification_counter
FROM	sys.stats s
		JOIN sys.stats_columns sc ON s.object_id = sc.object_id AND s.stats_id = sc.stats_id
		JOIN sys.columns c ON sc.object_id = c.object_id AND sc.column_id = c.column_id
		JOIN sys.objects o ON s.object_id = o.object_id
		CROSS APPLY sys.dm_db_stats_properties (s.object_id, s.stats_id) sp
WHERE	o.name = '[TblName]'
ORDER BY o.name
		,s.stats_id
		,sc.stats_column_id;

-- statistics info (including histogram)
DBCC SHOW_STATISTICS ('[TblName]', '[StatName]');

-- \/\/ CARDINALITY ESTIMATOR HELPER \/\/ --

--How to calculate row estimates for multiple single column statistics (CE assumes a correlation)
--Find Histogram bucket for param value then calculate % Rows: EQ_ROWS/ROWS or AVG_RANGE_ROWS/ROWS
--EstimatedRows calc wi/ percentage order from MOST to LEAST selective: A% * SQRT(B%) * SQRT(SQRT(C%)) * Rows = EstimatedRows

--How to calculate row estimates for multi-column statistics
--Find Histogram bucket for multi-column statistic (will be equivalent to 1st column in statistic): Rows
--Find Histogram bucket for 2nd, 3rdor 4th column statistic and calculate % Rows: EQ_ROWS/ROWS or AVG_RANGE_ROWS/ROWS
--Rows * SQRT(A%) * SQRT(SQRT(B%)) = EstimatedRows

--Filtered Statistics
--Why? B/c statistics Histogram limited to 200 steps.
--Works for literal values or OPTION RECOMPILE but not for params (b/c query plan reuse)

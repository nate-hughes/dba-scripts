USE [DBName];

DECLARE @TblName VARCHAR(128) = NULL;

-- whats stats exist for the table
--EXEC sp_helpstats @objname = 'User';
SELECT	SCHEMA_NAME(o.schema_id) AS SchemaName
		,o.name AS TblName
		,c.name AS ColName
		,s.name AS StatName
		,sp.last_updated
		,DATEDIFF(DAY,sp.last_updated,GETDATE()) AS DaysOld
		,sp.modification_counter -- Total number of modifications for the leading statistics column (the column on which the histogram is built) since the last time statistics were updated.
		,s.auto_created
		,s.user_created
		,s.no_recompute
		,s.object_id
		,s.stats_id
		,sc.stats_column_id
		,sc.column_id
		,sp.rows			-- Total number of rows in the table or indexed view when statistics were last updated.
		,sp.rows_sampled	-- Total number of rows sampled for statistics calculations.
		,sp.steps			-- Number of steps in the histogram.
FROM	sys.stats s
		JOIN sys.stats_columns sc ON s.object_id = sc.object_id AND s.stats_id = sc.stats_id
		JOIN sys.columns c ON sc.object_id = c.object_id AND sc.column_id = c.column_id
		JOIN sys.objects o ON s.object_id = o.object_id
		CROSS APPLY sys.dm_db_stats_properties (s.object_id, s.stats_id) sp
WHERE	(o.name = @TblName OR @TblName IS NULL)
AND		OBJECTPROPERTY(s.OBJECT_ID,'IsUserTable') = 1
AND		(s.auto_created = 1 OR s.user_created = 1)
ORDER BY SchemaName
		,o.name
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


--DBCC UPDATEUSAGE(0);

DECLARE @pgsz NUMERIC(19,10);

SELECT	@pgsz = [low] * 0.0009765625 /*KB*/ * 0.0009765625 /*MB*/
FROM	[master].dbo.spt_values
WHERE	number = 1
AND		type = 'E';

DECLARE @l_DBId INT
		,@l_TblId INT
		,@l_Table VARCHAR(128) = 'schema.table';

SET @l_DBId = DB_ID();
SET @l_TblId = OBJECT_ID(@l_Table);

SELECT	TblId = o.object_id
		, TblName = o.name
		, [Rows] = MAX(CASE WHEN i.index_id IN(0,1) THEN p.rows END)
		, Reserved = CONVERT(NUMERIC(9,1),SUM(a.total_pages) * @pgsz)
		, Data = CONVERT(NUMERIC(9,1),SUM(CASE WHEN i.index_id IN(0,1) THEN a.data_pages END) * @pgsz)
		, Indx = CONVERT(NUMERIC(9,1),ISNULL(SUM(CASE WHEN i.index_id > 1 THEN a.data_pages END),0) * @pgsz)
		, Unused = CONVERT(NUMERIC(9,1),(SUM(a.total_pages) - SUM(a.used_pages)) * @pgsz)
FROM	sys.objects o
		INNER JOIN sys.indexes i
			ON o.object_id = i.object_id
		INNER JOIN sys.partitions p
			ON i.object_id = p.OBJECT_ID
			AND i.index_id = p.index_id
		INNER JOIN sys.allocation_units a
			ON p.partition_id = a.container_id
WHERE	o.type = 'U'
AND		o.is_ms_shipped = 0
AND		(o.object_id = @l_TblId OR @l_TblId IS NULL)
GROUP BY o.object_id
		, o.name
ORDER BY 4 DESC
		, 2; 

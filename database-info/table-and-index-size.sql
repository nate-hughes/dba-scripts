
DBCC UPDATEUSAGE(0);

DECLARE @pgsz NUMERIC(19,10);

SELECT	@pgsz = [low] * 0.0009765625 /*KB*/ * 0.0009765625 /*MB*/
FROM	[master].dbo.spt_values
WHERE	number = 1
AND		type = 'E';

/*
exec sp_spaceused 'ZipCode';
exec sp_spaceused 'StatisticalArea_to_Zip';
*/

DECLARE @l_DBId INT;

SET @l_DBId = DB_ID();

SELECT	TblId = o.object_id
		, TblName = o.name
		, IndxId = i.index_id
		, IndxName = i.name
		, DataSpaceType = d.[type]
		, DataSpaceName = d.name
		, [Partition] = p.partition_number
		, [Compression] = p.data_compression_desc
		, [Rows] = p.[rows]
		, Reserved = CONVERT(NUMERIC(9,1),a.total_pages * @pgsz)
		, Data = CONVERT(NUMERIC(9,1),CASE WHEN i.index_id IN(0,1) THEN a.data_pages END * @pgsz)
		, Indx = CONVERT(NUMERIC(9,1),ISNULL(CASE WHEN i.index_id > 1 THEN a.data_pages END,0) * @pgsz)
		, Unused = CONVERT(NUMERIC(9,1),(a.total_pages - a.used_pages) * @pgsz)
FROM	sys.objects o
		INNER JOIN sys.indexes i
			ON o.object_id = i.object_id
		INNER JOIN sys.partitions p
			ON i.object_id = p.OBJECT_ID
			AND i.index_id = p.index_id
		INNER JOIN sys.allocation_units a
			ON p.partition_id = a.container_id
		INNER JOIN sys.data_spaces d
			ON i.data_space_id = d.data_space_id
WHERE	o.type = 'U'
AND		o.is_ms_shipped = 0
ORDER BY o.name
		, i.index_id; 

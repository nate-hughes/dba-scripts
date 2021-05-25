DECLARE @l_TableName VARCHAR(128) = 'Schema.TableName'
		,@l_TableId INT;

SET @l_TableId = OBJECT_ID(@l_TableName);

SELECT	OBJECT_NAME(i.object_id) AS TableName
		,i.name AS IndexName
		,ps.index_type_desc AS IndexType
		,TRY_CONVERT(NUMERIC(9,2), ps.page_count * 1.0  / 128) AS IndexSize_MB
		,TRY_CONVERT(NUMERIC(9,2), ps.avg_fragmentation_in_percent) AS FragmentationPercentage
		,TRY_CONVERT(NUMERIC(9,2), ps.avg_page_space_used_in_percent) AS PageDensityPercentage
FROM	sys.indexes i
		CROSS APPLY sys.dm_db_index_physical_stats(DB_ID(), i.object_id, i.index_id, NULL, 'SAMPLED') ps
WHERE	i.object_id = @l_TableId
ORDER BY ps.index_type_desc
		,FragmentationPercentage DESC;

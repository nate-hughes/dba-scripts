DECLARE @TblName NVARCHAR(128)
		, @IndxId INT
		, @ColList NVARCHAR(2000)
		, @ColIncList NVARCHAR(2000)
		, @TblId INT;

SET @TblName = NULL;

IF @TblName IS NOT NULL
	SET @TblId = OBJECT_ID(@TblName);

DECLARE @IndxCols TABLE (
	TblId INT
	, IndxId INT
	, [Columns] NVARCHAR(4000)
	, [Included Columns] NVARCHAR(4000)
);

INSERT INTO @IndxCols (
	TblId
	, IndxId
	, [Columns]
	, [Included Columns]
)
SELECT	i.object_id
		, i.index_id
		, [Columns] = STUFF((
				SELECT	CASE WHEN ic.is_descending_key = 1 THEN ', ' + c.name + '(-)'
								ELSE ', ' + c.name
							END
				FROM	sys.index_columns ic
						INNER JOIN sys.columns c
							ON c.object_id = ic.object_id
							AND c.column_id = ic.column_id
				WHERE	ic.object_id = i.object_id
				AND		ic.index_id = i.index_id
				AND		ic.is_included_column = 0
				ORDER BY ic.key_ordinal
				FOR XML PATH ('')
			),1,2,'')
		, [Included Columns] = STUFF((
				SELECT	CASE WHEN ic.is_descending_key = 1 THEN ', ' + c.name + '(-)'
								ELSE ', ' + c.name
							END
				FROM	sys.index_columns ic
						INNER JOIN sys.columns c
							ON c.object_id = ic.object_id
							AND c.column_id = ic.column_id
				WHERE	ic.object_id = i.object_id
				AND		ic.index_id = i.index_id
				AND		ic.is_included_column = 1
				ORDER BY ic.key_ordinal
				FOR XML PATH ('')
			),1,2,'')
FROM	sys.indexes i
WHERE	OBJECTPROPERTY(i.[object_id],'IsUserTable') = 1
AND		i.[object_id] = ISNULL(@TblId, i.[object_id]);


SELECT	TblName = OBJECT_NAME(s.[object_id])
		, IndxName = i.name
		, IndxId = i.index_id
		, IndxType = i.type_desc
		, PK = i.is_primary_key
		, AK = i.is_unique
		, FileGroup =d.name
		, IndxColumns = c.[Columns]
		, IncludedColumns = c.[Included Columns]
		, TotalReads = SUM(user_seeks + user_scans + user_lookups)
		, TotalWrites = SUM(user_updates)
FROM	sys.dm_db_index_usage_stats AS s
		INNER JOIN sys.indexes AS i
			ON s.[object_id] = i.[object_id]
			AND i.index_id = s.index_id
		INNER JOIN sys.data_spaces AS d
			ON i.data_space_id = d.data_space_id
		INNER JOIN @IndxCols c
			ON i.object_id = c.TblId
			AND i.index_id = c.IndxId
WHERE	OBJECTPROPERTY(s.[object_id],'IsUserTable') = 1
AND		s.database_id = DB_ID()
AND		s.[object_id] = ISNULL(@TblId, s.[object_id])
GROUP BY OBJECT_NAME(s.[object_id])
	, i.name
	, i.index_id
	, i.type_desc
	, i.is_unique
	, i.is_primary_key
	, d.name
	, c.[Columns]
	, c.[Included Columns]
ORDER BY OBJECT_NAME(s.[object_id])
	, i.index_id
	, TotalWrites DESC
	, TotalReads DESC
OPTION (RECOMPILE);

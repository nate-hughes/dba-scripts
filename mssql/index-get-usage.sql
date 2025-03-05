DECLARE	@TblName sysname = NULL--N'TblName'
		,@TblId INT;

SET @TblId = OBJECT_ID(@TblName);

SELECT	SCHEMA_NAME(o.schema_id) AS [SCHEMA]
		,o.name AS [TABLE]
		,i.name AS [INDEX]
		,ISNULL(s.USER_SEEKS,0) AS USER_SEEKS
		,ISNULL(s.USER_SCANS,0) AS USER_SCANS
		,ISNULL(s.USER_LOOKUPS,0) AS USER_LOOKUPS
		,ISNULL(s.USER_UPDATES,0) AS USER_UPDATES
FROM	SYS.INDEXES AS I
		JOIN SYS.OBJECTS AS O ON I.object_id = O.object_id
		LEFT JOIN SYS.DM_DB_INDEX_USAGE_STATS AS S
			ON I.object_id = S.object_id
			AND I.index_id = S.index_id
			AND S.database_id = DB_ID()
WHERE	o.object_id = @TblId
OR		(@TblName IS NULL
		AND OBJECTPROPERTY(I.object_id,'IsUserTable') = 1)
ORDER BY SCHEMA_NAME(o.schema_id)
		,o.name
		,i.index_id;


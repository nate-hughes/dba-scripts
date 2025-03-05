SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO

USE TempDb;
GO

DECLARE	@pgsz NUMERIC(19,10);

SELECT	@pgsz = [low] * 0.0009765625 /*KB*/ * 0.0009765625 /*MB*/
FROM	[master].dbo.spt_values
WHERE	number = 1
AND		type = 'E';

DECLARE @TempDbFiles TABLE (
	FileName VARCHAR(128)
	,FileGroupName VARCHAR(128)
	,Size BIGINT
	,SpaceUsed BIGINT
	,type TINYINT
	,file_id INT
	,physical_name VARCHAR(260)
);

	INSERT @TempDbFiles (
		FileName, FileGroupName, Size, SpaceUsed, type, file_id, physical_name
	)
	SELECT	f.name
			,CASE WHEN f.type = 1 THEN 'LOG'
				ELSE s.name
			END
			,CONVERT(BIGINT, f.size * @pgsz)
			,CONVERT(BIGINT, FILEPROPERTY(f.name, 'SpaceUsed') * @pgsz)
			,f.type
			,f.file_id
			,f.physical_name
	FROM	sys.database_files f
			LEFT OUTER JOIN sys.data_spaces s
				ON f.data_space_id = s.data_space_id;

				
SELECT	 row_number() over (order by type, file_id ),
		FileName,
		FileGroupName,
		Size,
		SpaceUsed,
		TRY_CONVERT(VARCHAR(50),CONVERT(NUMERIC(4,1), SpaceUsed * 1.0 / Size * 100)) as FileSizeUsedPct,
		--TRY_CONVERT(VARCHAR(50),(Size - SpaceUsed),100),
		TRY_CONVERT(VARCHAR(50),CONVERT(NUMERIC(4,1), (Size - SpaceUsed) * 1.0 / Size * 100)) as FileSizeUnusedPct,
		physical_name
FROM  @TempDbFiles


 -- total space usage by object type
SELECT	TRY_CONVERT(BIGINT, SUM (user_object_reserved_page_count) * (8.0/1024.0)) AS [User Objects (MB)]
		,TRY_CONVERT(BIGINT, SUM (internal_object_reserved_page_count) * (8.0/1024.0)) AS [Internal Objects (MB)]
		,TRY_CONVERT(BIGINT, SUM (version_store_reserved_page_count) * (8.0/1024.0)) AS [Version Store (MB)]
		,TRY_CONVERT(BIGINT, SUM (mixed_extent_page_count)* (8.0/1024.0)) AS [Mixed Extent (MB)]
		,TRY_CONVERT(BIGINT, SUM (unallocated_extent_page_count)* (8.0/1024.0)) AS [Unallocated (MB)]
FROM	sys.dm_db_file_space_usage;

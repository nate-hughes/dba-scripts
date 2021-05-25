USE [DATABASE_NAME];
GO
SET NOCOUNT ON;

DECLARE	@Rows INT
        ,@BatchSize INT = 4000
        ,@Completed INT = 0
        ,@Total INT;

-- \/\/ Populate temp table with PK column(s) \/\/ --
SELECT	[SOME_ID]
INTO	#temp_ids
FROM	[TABLE_NAME]
WHERE	[SOME_COLUMN] IS NULL;

SELECT @Total = COUNT(*) FROM #temp_ids;

CREATE TABLE #temp_upd (Id UNIQUEIDENTIFIER);

WHILE EXISTS (SELECT 1 FROM #temp_ids)
BEGIN
	DELETE	TOP (@BatchSize)
	FROM	#temp_ids
	OUTPUT deleted.Id INTO #temp_upd;  

	UPDATE	t
	SET		[SOME_COLUMN] = 'Some Value'
	FROM	[TABLE_NAME] t
			JOIN #temp_upd tmp ON t.[SOME_ID] = tmp.Id;

	SET @Rows = @@ROWCOUNT;
	SET @Completed = @Completed + @Rows;

	PRINT 'Completed ' + cast(@Completed as varchar(10)) + '/' + cast(@Total as varchar(10));

	TRUNCATE TABLE #temp_upd;
END;

DROP TABLE IF EXISTS #temp_upd;
DROP TABLE IF EXISTS #temp_ids;

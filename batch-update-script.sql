USE [MarlettePROD];
GO
SET NOCOUNT ON;

-- \/\/ Populate temp table with PK column(s) \/\/ --
DROP TABLE IF EXISTS #temp_ids;
CREATE TABLE #temp_ids (loan_transaction_id bigint, somevalue varchar(50));

insert #temp_ids (loan_transaction_id,somevalue)
values (134455883,'a'), (134503885, 'b');

DECLARE	@Rows INT
        ,@BatchSize INT = 4000
        ,@Completed INT = 0
        ,@Total INT;

SELECT @Total = COUNT(*) FROM #temp_ids;

CREATE TABLE #temp_upd (Id BIGINT);

WHILE EXISTS (SELECT 1 FROM #temp_ids)
BEGIN
	DELETE	TOP (@BatchSize)
	FROM	#temp_ids
	OUTPUT deleted.loan_transaction_id INTO #temp_upd;  

	UPDATE	lt
	SET		somecolumn = ti.somevalue
	FROM	loan.transactions lt
			JOIN #temp_upd tmp ON lt.loan_transaction_id = tmp.Id
			JOIN #temp_ids ti ON lt.loan_transaction_id = ti.Id;

	SET @Rows = @@ROWCOUNT;

	INSERT 	loan.transactions
	SELECT	*
	FROM	#temp_upd tmp
			JOIN #temp_ids ti ON tmp.Id = ti.Id
	AND		NOT EXISTS (
				SELECT 1
				FROM loan.transactions
				WHERE loan_transaction_id = tmp.Id);

	SET @Rows += ISNULL(@@ROWCOUNT,0);
	SET @Completed = @Completed + @Rows;

	PRINT 'Completed ' + cast(@Completed as varchar(10)) + '/' + cast(@Total as varchar(10));

	TRUNCATE TABLE #temp_upd;
END;

DROP TABLE IF EXISTS #temp_upd;
DROP TABLE IF EXISTS #temp_ids;

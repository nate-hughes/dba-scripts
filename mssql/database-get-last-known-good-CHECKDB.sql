
DECLARE @SqlCmds TABLE (
	Id INT
	,SqlCmd NVARCHAR(200)
);

DECLARE @Result TABLE (
	DbName VARCHAR(128)
	,LastKnownGoodCheckDb SQL_VARIANT
);

INSERT @SqlCmds (Id, SqlCmd)
SELECT	database_id
		--,N'DBCC DBINFO(''' + name + ''') WITH TABLERESULTS'
		,N'SELECT ''' + name + ''' AS dbname, DATABASEPROPERTYEX(''' + name + ''', ''LastGoodCheckDbTime'') AS LastKnownGoodCheckDb'
		--,sys.fn_hadr_is_primary_replica (name) AS is_primary_replica
FROM	master.sys.databases
WHERE	(
			replica_id IS NULL
			AND name <> 'tempdb'
		)
OR		(
			replica_id IS NOT NULL
			AND sys.fn_hadr_is_primary_replica (name) = 1
		);

DECLARE @Id INT = 0
		,@SqlCmd NVARCHAR(200);

WHILE EXISTS (SELECT 1 FROM @SqlCmds WHERE Id > @Id)
BEGIN
	SELECT	TOP (1)
			@Id = Id
			,@SqlCmd = SqlCmd
	FROM	@SqlCmds
	WHERE	Id > @Id
	ORDER BY Id;

	INSERT @Result (DbName, LastKnownGoodCheckDb)
	EXEC sp_executesql @SqlCmd;
END;

SELECT	DbName
		,TRY_CONVERT(DATETIME,LastKnownGoodCheckDb) AS LastKnownGoodCheckDb
FROM	@Result
ORDER BY DbName;

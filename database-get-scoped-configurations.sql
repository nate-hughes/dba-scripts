
DECLARE @Version VARCHAR(50) = LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(128)),2)
		,@SQL NVARCHAR(MAX);
		
IF @Version = 13
	SET @SQL = N'
	SELECT	DB_NAME()
			,name
			,value
			,value_for_secondary
			,NULL AS is_value_default
	FROM	sys.database_scoped_configurations;'
ELSE IF @Version > 13
	SET @SQL = N'
	SELECT	DB_NAME()
			,name
			,value
			,value_for_secondary
			,is_value_default
	FROM	sys.database_scoped_configurations;'

EXEC (@SQL);
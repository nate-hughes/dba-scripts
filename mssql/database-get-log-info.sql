DECLARE @DatabaseName NVARCHAR(128) = 'DBName'
		,@DatabaseId INT;
		
SET @DatabaseId = DB_ID(@DatabaseName);

SELECT	name, recovery_model_desc, log_reuse_wait_desc
FROM	sys.databases
WHERE	name = @DatabaseName;

SELECT	*
FROM	sys.dm_db_log_info (@DatabaseId);

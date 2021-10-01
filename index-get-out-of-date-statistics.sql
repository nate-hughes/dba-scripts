DECLARE	@DBName NVARCHAR(128) = NULL
		,@TblName NVARCHAR(128) = NULL
		,@SQL NVARCHAR(MAX);

SET @SQL =
    CASE
		WHEN @DBName IS NULL THEN 'USE [?];'
        ELSE 'USE ' + @DBName + ';'
    END
    + '
		SELECT	DB_NAME() AS DBName
				,SCHEMA_NAME(obj.schema_id) AS SchemaName	
				,sch.name AS TblName
				,stat.name AS StatName
				,sp.last_updated AS LastUpdated
				,DATEDIFF(DAY,sp.last_updated,GETDATE()) AS DaysOld
				,sp.modification_counter AS ModCounter
				,'' UPDATE STATISTICS ['' + DB_NAME() + ''].['' + sch.name + ''].['' + obj.name + ''] ['' + stat.name + ''];'' AS UpdScript
		FROM	sys.stats stat
				JOIN sys.objects obj ON stat.object_id = obj.object_id
				JOIN sys.schemas sch ON obj.schema_id = sch.schema_id
				CROSS APPLY sys.dm_db_stats_properties(obj.object_id, stat.stats_id) sp
		WHERE	obj.type = ''U''
		AND		(
					(sp.modification_counter * 1.0 / sp.rows) > 0.3
					OR DATEDIFF(DAY,sp.last_updated,GETDATE()) > 30
				)'
	+ CASE
		WHEN @TblName IS NULL THEN ';'
        ELSE ' AND		stat.object_id = OBJECT_ID(''' + @TblName  + ''');'
    END;

IF @DBName IS NULL
    EXEC sys.sp_MSforeachdb @SQL;
ELSE
    EXEC sys.sp_executesql @statement = @SQL;

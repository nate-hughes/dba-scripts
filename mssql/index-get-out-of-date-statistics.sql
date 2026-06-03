/*
This script finds user-table statistics that may be stale and generates an UPDATE STATISTICS command for each one.

Stats considered stale if either:
- more than 30% of their rows changed since the last stats update
- have not been updated in more than 30 days

It can be run either:
- across all databases when @DBName IS NULL
- against one specific database when @DBName is set
- against one specific table when @TblName is set
*/

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
				,obj.name AS TblName
				,stat.name AS StatName
				,sp.last_updated AS LastUpdated
				,DATEDIFF(DAY,sp.last_updated,GETDATE()) AS DaysOld
                ,sp.rows AS StatRows
				,CAST(sp.modification_counter * 100.0 / NULLIF(sp.rows, 0) AS DECIMAL(9,2)) AS ModPct
                ,CASE WHEN sp.last_updated IS NULL THEN ''Never Updated / No Stats Blob''
					WHEN (sp.modification_counter * 1.0 / NULLIF(sp.rows, 0)) > 0.3
                         AND DATEDIFF(DAY, sp.last_updated, GETDATE()) > 30 THEN ''ModPct > 30% and DaysOld > 30''
                    WHEN (sp.modification_counter * 1.0 / NULLIF(sp.rows, 0)) > 0.3 THEN ''ModPct > 30%''
                    WHEN DATEDIFF(DAY, sp.last_updated, GETDATE()) > 30 THEN ''DaysOld > 30''
                    ELSE ''Not Flagged''
                 END AS StaleReason
                ,CASE WHEN stat.no_recompute = 1 THEN ''Y'' ELSE ''N'' END AS NoRecompute -- stats that will not auto-update
				,'' UPDATE STATISTICS ['' + DB_NAME() + ''].['' + sch.name + ''].['' + obj.name + ''] ['' + stat.name + ''];'' AS UpdScript
		FROM	sys.stats stat
				JOIN sys.objects obj ON stat.object_id = obj.object_id
				JOIN sys.schemas sch ON obj.schema_id = sch.schema_id
				CROSS APPLY sys.dm_db_stats_properties(obj.object_id, stat.stats_id) sp
		WHERE	obj.type = ''U''
		AND		(
					(sp.modification_counter * 1.0 / NULLIF(sp.rows, 0)) > 0.3
					OR (
						sp.last_updated IS NULL
						OR DATEDIFF(DAY,sp.last_updated,GETDATE()) > 30
					)
				)'
	+ CASE
		WHEN @TblName IS NULL THEN ' ORDER BY DBName, SchemaName, TblName;'
        ELSE ' AND		stat.object_id = OBJECT_ID(''' + @TblName  + ''') ORDER BY DBName, SchemaName, TblName;'
    END;

IF @DBName IS NULL
    EXEC sys.sp_MSforeachdb @SQL;
ELSE
    EXEC sys.sp_executesql @statement = @SQL;

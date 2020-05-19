DECLARE @DBName NVARCHAR(128) = NULL
       ,@SQL    NVARCHAR(MAX);

SET @SQL =
    CASE        WHEN @DBName IS NULL THEN 'USE [?];'
                ELSE 'USE ' + @DBName + ';'
    END
    + '
			SELECT	DISTINCT
					[DBId] = DB_ID()
					, DBName = DB_NAME()
					, TblId = o.object_id
					, TblName = o.name
					, StatName = si.name
					, LastUpdDate = STATS_DATE(si.id, si.indid)
					, UpdScript = '' UPDATE STATISTICS ['' + DB_NAME() + ''].['' + s.name + ''].['' + o.name + ''] ['' + si.name + ''];''
			FROM	sys.sysindexes si
					INNER JOIN (
						SELECT	object_id
								, rowcnt = SUM(rows)
						FROM	sys.partitions
						GROUP BY object_id
						HAVING SUM(rows) > 0
					) p ON si.id = p.object_id
					INNER JOIN sys.objects o ON p.object_id = o.object_id
					INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
			WHERE	((si.rowmodctr * 1.0 / p.rowcnt) > 0.3
					OR DATEDIFF(DAY,STATS_DATE(si.id, si.indid),GETDATE()) > 30)
			AND		o.type = ''U''
			AND		si.name IS NOT NULL';

IF @DBName IS NULL
    EXEC sys.sp_MSforeachdb @SQL;
ELSE
    EXEC sys.sp_executesql @statement = @SQL;

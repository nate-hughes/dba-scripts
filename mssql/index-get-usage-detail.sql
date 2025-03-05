
DECLARE @sql_indxinfo NVARCHAR(4000)
		,@sql_indxsize NVARCHAR(4000)
		,@Version VARCHAR(50) = LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(128)),2)
		,@IsHadrEnabled TINYINT = CONVERT(TINYINT,SERVERPROPERTY ('IsHadrEnabled'))
		,@RoleDesc NVARCHAR(60) = 'PRIMARY'
		,@DBName NVARCHAR(128) = NULL
;

if OBJECT_ID('tempdb..#IndxInfo') is not null drop table #IndxInfo;
create table #IndxInfo (
	databaseid INT NOT NULL
	,objectid INT NOT NULL
	,indexid INT NOT NULL
	,databasename VARCHAR(128) NOT NULL
	,schemaname VARCHAR(128) NOT NULL
	,tablename VARCHAR(128) NOT NULL
	,indexname VARCHAR(128) NULL
	,indextype TINYINT NOT NULL
	,columns VARCHAR(4000) NULL
	,included_columns VARCHAR(4000) NULL
	,is_unique BIT NOT NULL
	,is_primary_key BIT NOT NULL
	,is_unique_constraint BIT NOT NULL
	,is_disabled BIT NOT NULL
	,has_filter BIT NOT NULL
	,filter_definition VARCHAR(4000) NULL
	,auto_created BIT NULL
	,fill_factor TINYINT NOT NULL
	,is_padded BIT NOT NULL
	,last_user_seek DATETIME NULL
	,last_user_scan DATETIME NULL
	,last_user_lookup DATETIME NULL
	,last_user_update DATETIME NULL
	,user_seeks BIGINT NULL
	,user_scans BIGINT NULL
	,user_lookups BIGINT NULL
	,user_updates BIGINT NULL
);

if OBJECT_ID('tempdb..#IndxSize') is not null drop table #IndxSize;
create table #IndxSize (
	databaseid INT NOT NULL
	,objectid INT NOT NULL
	,indexid INT NOT NULL
	,partitions INT NOT NULL
	,rows BIGINT NOT NULL
	,total_pages BIGINT NOT NULL
	,used_pages BIGINT NOT NULL
	,in_row_data_pages BIGINT NOT NULL
	,lob_data_pages BIGINT NOT NULL
	,row_overflow_data_pages BIGINT NOT NULL
	,data_compression TINYINT NOT NULL
);

SET @sql_indxinfo = N'USE [?]; '
IF @DBName IS NULL
	SET @sql_indxinfo += N'IF DB_ID() > 4 BEGIN ';
ELSE
	SET @sql_indxinfo += N'IF DB_NAME() = ''' + @DBName + ''' BEGIN ';
SET @sql_indxinfo += N'
INSERT #IndxInfo
SELECT	DB_ID()
		,i.object_id
		,i.index_id
		,DB_NAME()
		,SCHEMA_NAME(o.schema_id)
		,o.name
		,i.name
		,i.type
       ,STUFF((
            SELECT	CASE WHEN ic.is_descending_key = 1 THEN '', '' + c.name + ''(-)'' ELSE '', '' + c.name END
            FROM	sys.index_columns ic
					JOIN sys.columns c
						ON  c.object_id = ic.object_id
						AND c.column_id = ic.column_id
            WHERE	ic.object_id = i.object_id
            AND		ic.index_id = i.index_id
            AND		ic.is_included_column = 0
            ORDER BY ic.key_ordinal
            FOR XML PATH('''')
        ), 1, 2, '''')
       ,STUFF((
            SELECT	CASE WHEN ic.is_descending_key = 1 THEN '', '' + c.name + ''(-)'' ELSE '', '' + c.name END
            FROM	sys.index_columns ic
					JOIN sys.columns c
						ON  c.object_id = ic.object_id
						AND c.column_id = ic.column_id
            WHERE	ic.object_id = i.object_id
            AND		ic.index_id = i.index_id
            AND		ic.is_included_column = 1
            ORDER BY ic.key_ordinal
            FOR XML PATH('''')
        ), 1, 2, '''')
		,i.is_unique
		,i.is_primary_key
		,i.is_unique_constraint
		,i.is_disabled
		,i.has_filter
		,i.filter_definition'
+ CASE WHEN @Version > 13 THEN '		,i.auto_created' ELSE '		,NULL' END +
'		,i.fill_factor
		,i.is_padded
		,u.last_user_seek
		,u.last_user_scan
		,u.last_user_lookup
		,u.last_user_update
		,u.user_seeks
		,u.user_scans
		,u.user_lookups
		,u.user_updates
FROM	sys.objects o
		JOIN sys.indexes i ON o.object_id = i.object_id
		LEFT JOIN sys.dm_db_index_usage_stats u ON i.object_id = u.object_id and i.index_id = u.index_id and u.database_id = DB_ID()
WHERE	OBJECTPROPERTY(o.object_id,''IsUserTable'') = 1;
END;'

SET @sql_indxsize = N'USE [?]; '
IF @DBName IS NULL
	SET @sql_indxsize += N'IF DB_ID() > 4 BEGIN ';
ELSE
	SET @sql_indxsize += N'IF DB_NAME() = ''' + @DBName + ''' BEGIN ';
SET @sql_indxsize += N'
INSERT #IndxSize
SELECT	DB_ID()
		,i.object_id
		,i.index_id
		,COUNT(p.partition_id)
		,SUM(p.rows)
		,SUM(a.used_pages)
		,SUM(a.total_pages)
		,SUM(a.in_row)
		,SUM(a.lob)
		,SUM(a.row_overflow)
		,p.data_compression
FROM	sys.indexes i
		JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
		JOIN (
			SELECT	container_id
					,SUM(used_pages) as used_pages
					,SUM(total_pages) as total_pages
					,SUM(CASE WHEN type = 1 THEN data_pages ELSE 0 END) as in_row
					,SUM(CASE WHEN type = 2 THEN data_pages ELSE 0 END) as lob
					,SUM(CASE WHEN type = 3 THEN data_pages ELSE 0 END) as row_overflow
			FROM	sys.allocation_units
			GROUP BY container_id
		) a ON p.partition_id = a.container_id
WHERE	OBJECTPROPERTY(i.object_id,''IsUserTable'') = 1
GROUP BY i.object_id
		,i.index_id
		,p.data_compression;
END;'

IF @IsHadrEnabled = 0
OR (
	@IsHadrEnabled = 1
	AND EXISTS (
		SELECT 1
		FROM sys.dm_hadr_availability_replica_states AS a
			JOIN sys.availability_replicas AS b
		ON b.replica_id = a.replica_id
		WHERE b.replica_server_name = @@SERVERNAME
		AND	a.role_desc = @RoleDesc
	)
)
BEGIN
	EXEC sp_msforeachdb @sql_indxinfo;
	EXEC sp_msforeachdb @sql_indxsize;
END;

SELECT	@@SERVERNAME AS servername
		,i.databasename
		,i.schemaname
		,i.tablename
		,i.indexname
		,i.indextype
		,i.columns
		,i.included_columns
		,i.is_unique
		,i.is_primary_key
		,i.is_unique_constraint
		,i.is_disabled
		,i.has_filter
		,i.filter_definition
		,i.auto_created
		,i.fill_factor
		,i.is_padded
		,s.partitions
		,s.rows
		,s.total_pages
		,s.used_pages
		,s.in_row_data_pages
		,s.lob_data_pages
		,s.row_overflow_data_pages
		,s.data_compression
		,i.last_user_seek
		,i.last_user_scan
		,i.last_user_lookup
		,i.last_user_update
		,i.user_seeks
		,i.user_scans
		,i.user_lookups
		,i.user_updates
FROM	#IndxInfo i
		JOIN #IndxSize s
			ON s.databaseid = i.databaseid
			AND s.objectid = i.objectid
			AND s.indexid = i.indexid
WHERE	i.databaseid > 4
ORDER BY i.databasename
		,i.schemaname
		,i.tablename
		,i.indextype;

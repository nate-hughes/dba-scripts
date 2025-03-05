
DECLARE @sql_tbls VARCHAR(4000)
		,@IsHadrEnabled TINYINT = CONVERT(TINYINT,SERVERPROPERTY ('IsHadrEnabled'))
		,@RoleDesc NVARCHAR(60) = 'PRIMARY';

CREATE TABLE #Tbl_DataDictionary (
	DBName VARCHAR(128)
	,SchemaName VARCHAR(128)
	,TblName VARCHAR(128)
	,Rows BIGINT
	,Reserved NUMERIC(9,1)
	,Data NUMERIC(9,1)
	,Indx NUMERIC(9,1)
	,Unused NUMERIC(9,1)
);

SET @sql_tbls = 'USE [?];
IF DB_ID() > 4
BEGIN
DECLARE @pgsz NUMERIC(19,10);

SELECT	@pgsz = [low] * 0.0009765625 /*KB*/ * 0.0009765625 /*MB*/
FROM	[master].dbo.spt_values
WHERE	number = 1
AND		type = ''E'';

INSERT #Tbl_DataDictionary
SELECT	DBName = DB_Name()
		,SCHEMA_NAME(o.schema_id)
		,TblName = o.name
		,[Rows] = MAX(CASE WHEN i.index_id IN(0,1) THEN p.rows END)
		,Reserved = CONVERT(NUMERIC(9,1),SUM(a.total_pages) * @pgsz)
		,Data = CONVERT(NUMERIC(9,1),SUM(CASE WHEN i.index_id IN(0,1) THEN a.data_pages END) * @pgsz)
		,Indx = CONVERT(NUMERIC(9,1),ISNULL(SUM(CASE WHEN i.index_id > 1 THEN a.data_pages END),0) * @pgsz)
		,Unused = CONVERT(NUMERIC(9,1),(SUM(a.total_pages) - SUM(a.used_pages)) * @pgsz)
FROM	sys.objects o
		INNER JOIN sys.indexes i
			ON o.object_id = i.object_id
		INNER JOIN sys.partitions p
			ON i.object_id = p.OBJECT_ID
			AND i.index_id = p.index_id
		INNER JOIN sys.allocation_units a
			ON p.partition_id = a.container_id
WHERE	o.type = ''U''
AND		o.is_ms_shipped = 0
GROUP BY o.object_id
		,o.schema_id
		,o.name;
END';

IF @IsHadrEnabled = 0
OR (
	@IsHadrEnabled = 1
	AND EXISTS (
		SELECT 1
		FROM sys.dm_hadr_availability_replica_states AS a
			JOIN sys.availability_replicas AS b
		ON b.replica_id = a.replica_id
		WHERE b.replica_server_name = @@SERVERNAME
		AND a.role_desc = @RoleDesc
	)
)
BEGIN
	EXEC sp_MSForEachDB @sql_tbls;
END;

SELECT	@@SERVERNAME as servername
		,DEFAULT_DOMAIN() AS domain
		,DBName
		,SchemaName
		,TblName
		,Rows
		,Reserved
		,Data
		,Indx
		,Unused
FROM	#Tbl_DataDictionary;

IF OBJECT_ID('tempdb..#Tbl_DataDictionary') IS NOT NULL
	DROP TABLE #Tbl_DataDictionary;

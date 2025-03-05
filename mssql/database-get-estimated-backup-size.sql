DECLARE @SQL NVARCHAR(4000);

DROP TABLE IF EXISTS #tmp_SpaceUsed;

CREATE TABLE #tmp_SpaceUsed (
	database_name nvarchar(128)
	,database_size varchar(18)
	,unallocated varchar(18)
	,reserved varchar(18)
	,data varchar(18)
	,index_size varchar(18)
	,unused varchar(18)
);

SET @SQL = N'USE [?];
INSERT #tmp_SpaceUsed
EXEC sp_spaceused @updateusage = ''true'', @oneresultset = 1';

EXEC sp_MSforeachdb @SQL;

-- Backup Size (MB) = ((Reserved (KB) – Unused (KB))/1024)/1024
SELECT	database_name
		,((CONVERT(BIGINT,TRIM(REPLACE(reserved,'KB',''))) - CONVERT(BIGINT,TRIM(REPLACE(unused,'KB','')))) / 1024) / 1024 AS ForecastSize_GB
		,1 AS RowId
FROM	#tmp_SpaceUsed
UNION
SELECT	'TOTAL' AS database_name
		,SUM(((CONVERT(BIGINT,TRIM(REPLACE(reserved,'KB',''))) - CONVERT(BIGINT,TRIM(REPLACE(unused,'KB',''))))) / 1024) / 1024 AS ForecastSize_GB
		,0 AS RowId
FROM	#tmp_SpaceUsed
ORDER BY 3, 1


--BACKUP DATABASE ema TO DISK = 'NUL' WITH COMPRESSION
--SELECT * FROM msdb.dbo.backupset
